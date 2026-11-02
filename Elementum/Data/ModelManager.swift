import SwiftUI
import Sapient
import BackgroundTasks

/// Tracks whether the on-device language model has been downloaded, and downloads it on request.
///
/// Sapient downloads with its own networking (not URLSession), so iOS can't carry the transfer on
/// while the app is suspended. To keep a 1 GB download from stalling:
/// - the screen is kept awake while downloading, so the app stays in the foreground;
/// - when the user leaves the app, iOS 26 continues it as a continued-processing background task
///   (with system progress); earlier iOS gets the usual short background grace period;
/// - a stalled or interrupted download is cancelled and restarted, and Sapient resumes from the
///   partial files it keeps, including automatically when the app comes back to the foreground.
@MainActor
final class ModelManager: ObservableObject {

    enum State: Equatable {
        case notDownloaded
        case downloading(progress: Double?)
        case ready
        case failed(String)
    }

    /// Devices with more than this much RAM get the full-precision model; the rest get the 4-bit one.
    /// (iOS reports slightly less than the marketing figure, so 6 GB phones land below this line.)
    nonisolated static let fullModelMinimumMemory: UInt64 = 6 * 1024 * 1024 * 1024

    /// Qwen2.5-1.5B-Instruct: the standard build on devices with enough memory, otherwise the Q4_K_M build (~1 GB),
    /// which SAPIENT's docs recommend on phones.
    nonisolated static let modelAlias: String =
        ProcessInfo.processInfo.physicalMemory > fullModelMinimumMemory ? "qwen2.5-1.5b" : "qwen2.5-1.5b-q4"

    // Keyed by alias so a different model choice is never mistaken for an already-downloaded one.
    private static let downloadedKey = "sapientModelDownloaded.\(modelAlias)"

    /// No new bytes for this long counts as a stall: cancel and resume.
    private static let stallTimeout: Duration = .seconds(20)
    /// Automatic resumes allowed per tap of Download, so a dead connection still ends in "failed".
    private static let maxAutomaticResumes = 5

    @Published private(set) var state: State
    @Published private(set) var downloadSizeBytes: UInt64?

    private var downloadTask: Task<Void, Never>?
    private var listener: ProgressListener?
    private var watchdog: Task<Void, Never>?

    /// Why the current attempt was cancelled, so its error is handled correctly.
    private enum StopReason { case user, stalled, backgroundTimeUp }
    private var stopReason: StopReason?
    private var automaticResumes = 0
    /// Set when the download was interrupted in the background; resumes on return.
    private var resumeWhenActive = false
    private var lastBytes: UInt64 = 0
    private var lastProgressAt = ContinuousClock.now
    /// When a cancel was requested; if the download never answers it, the attempt is abandoned.
    private var cancelRequestedAt: ContinuousClock.Instant?
    /// Identifies the current attempt, so a late result from an abandoned one is ignored.
    private var attemptID = UUID()
    private static let unresponsiveTimeout: Duration = .seconds(30)

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var continuedTask: AnyObject?   // BGContinuedProcessingTask on iOS 26+
    private var activeObserver: NSObjectProtocol?

    init() {
        // Weights live in Caches so the OS can reclaim them and uninstall removes them.
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            setCacheDir(path: caches.path)
        }
        state = UserDefaults.standard.bool(forKey: Self.downloadedKey) ? .ready : .notDownloaded

        activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.appBecameActive() }
        }
    }

    func loadDownloadSize() async {
        guard downloadSizeBytes == nil else { return }
        downloadSizeBytes = try? await modelDownloadSize(model: Self.modelAlias)
    }

    // MARK: - Download

    /// Starts the download from the button. Resets the automatic-resume budget.
    func download() {
        automaticResumes = 0
        startAttempt()
    }

    func cancelDownload() {
        resumeWhenActive = false
        requestStop(.user)
    }
    
    private func requestStop(_ reason: StopReason) {
        guard stopReason == nil || reason == .user else { return }
        stopReason = reason
        cancelRequestedAt = .now
        listener?.cancel()
    }

    private func startAttempt() {
        guard downloadTask == nil else { return }
        stopReason = nil
        cancelRequestedAt = nil
        resumeWhenActive = false
        let attempt = UUID()
        attemptID = attempt

        // Keep the last known progress on a resume, so the bar doesn't jump back to "Starting".
        if case .downloading = state {} else { state = .downloading(progress: nil) }
        setScreenKeptAwake(true)
        beginBackgroundWork()

        let listener = ProgressListener { [weak self] downloaded, total in
            Task { @MainActor in self?.handleProgress(downloaded: downloaded, total: total) }
        }
        self.listener = listener
        lastProgressAt = .now
        startWatchdog()

        downloadTask = Task {
            do {
                try await downloadModel(model: Self.modelAlias, listener: listener)
                guard attempt == attemptID else { return }
                if stopReason == .user {
                    finish(with: .notDownloaded)
                } else {
                    UserDefaults.standard.set(true, forKey: Self.downloadedKey)
                    finish(with: .ready)
                }
            } catch {
                guard attempt == attemptID else { return }
                handleFailure(error)
            }
        }
    }

    private func handleProgress(downloaded: UInt64, total: UInt64) {
        guard case .downloading(let shown) = state else { return }
        // A resumed download reports 0 while it checks its partial files, then jumps to
        // the saved amount; keep showing the last value instead of flashing back to 0%.
        if downloaded == 0, let shown, shown > 0 { return }
        if downloaded != lastBytes {
            lastBytes = downloaded
            lastProgressAt = .now
        }
        let fraction = total > 0 ? Double(downloaded) / Double(total) : nil
        state = .downloading(progress: fraction)
        updateContinuedTaskProgress(fraction)
    }

    private func handleFailure(_ error: Error) {
        switch stopReason {
        case .user:
            finish(with: .notDownloaded)
        case .stalled where automaticResumes < Self.maxAutomaticResumes:
            // Sapient keeps the partial files, so this picks up where it stopped.
            automaticResumes += 1
            endAttempt()
            startAttempt()
        case .backgroundTimeUp:
            // Out of background time: pause and resume when the user comes back.
            endAttempt()
            resumeWhenActive = true
            endBackgroundWork(success: false)
        default:
            if UIApplication.shared.applicationState != .active,
               automaticResumes < Self.maxAutomaticResumes {
                // The connection dropped while the app was in the background.
                endAttempt()
                resumeWhenActive = true
                endBackgroundWork(success: false)
            } else {
                finish(with: .failed(error.localizedDescription))
            }
        }
    }

    /// Clears the per-attempt state; the download itself may start again.
    private func endAttempt() {
        watchdog?.cancel()
        watchdog = nil
        downloadTask = nil
        listener = nil
    }

    private func finish(with newState: State) {
        endAttempt()
        state = newState
        resumeWhenActive = false
        setScreenKeptAwake(false)
        endBackgroundWork(success: newState == .ready)
    }

    private func appBecameActive() {
        // Time spent suspended isn't a stall; give the connection a fresh window.
        lastProgressAt = .now
        guard resumeWhenActive, downloadTask == nil else { return }
        automaticResumes += 1
        startAttempt()
    }

    // MARK: - Stall watchdog

    private func startWatchdog() {
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard let self, !Task.isCancelled else { return }
                // A cancel the download never answered: abandon it so the app can't hang.
                if let asked = self.cancelRequestedAt,
                   ContinuousClock.now - asked > Self.unresponsiveTimeout {
                    self.abandonUnresponsiveAttempt()
                    return
                }
                // Only judge stalls in the foreground; background has its own handling.
                guard UIApplication.shared.applicationState == .active,
                      ContinuousClock.now - self.lastProgressAt > Self.stallTimeout,
                      self.stopReason == nil else { continue }
                self.requestStop(.stalled)
            }
        }
    }

    private func abandonUnresponsiveAttempt() {
        let reason = stopReason
        attemptID = UUID()   // its late result, if any, is ignored
        if reason == .user {
            finish(with: .notDownloaded)
        } else if reason == .backgroundTimeUp {
            endAttempt()
            resumeWhenActive = true
        } else {
            finish(with: .failed("The download stopped responding. Check your connection and try again."))
        }
    }
    
    // MARK: - Screen and background

    /// Keeps the screen from auto-locking while downloading, then restores normal auto-lock.
    private func setScreenKeptAwake(_ awake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = awake
    }

    private func beginBackgroundWork() {
        if #available(iOS 26.0, *) {
            if continuedTask == nil { submitContinuedProcessingTask() }
        }
        if backgroundTask == .invalid {
            backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "Model download") { [weak self] in
                Task { @MainActor in self?.backgroundTimeExpired() }
            }
        }
    }

    private func backgroundTimeExpired() {
        // Continued processing (iOS 26) keeps the download going; only pause without it.
        if continuedTask == nil, downloadTask != nil {
            requestStop(.backgroundTimeUp)
        }
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    private func endBackgroundWork(success: Bool) {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        if #available(iOS 26.0, *), let task = continuedTask as? BGContinuedProcessingTask {
            task.setTaskCompleted(success: success)
        }
        continuedTask = nil
    }

    @available(iOS 26.0, *)
    private func submitContinuedProcessingTask() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let identifier = "\(bundleID).model-download.\(UUID().uuidString)"
        let registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { [weak self] task in
            guard let task = task as? BGContinuedProcessingTask else { return }
            MainActor.assumeIsolated { self?.attach(task) }
        }
        guard registered else { return }
        let request = BGContinuedProcessingTaskRequest(
            identifier: identifier,
            title: "Downloading Combine model",
            subtitle: "Elementum keeps downloading in the background"
        )
        // Start now or not at all; the download is already running.
        request.strategy = .fail
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Continued processing unavailable: \(error)")
        }
    }

    @available(iOS 26.0, *)
    private func attach(_ task: BGContinuedProcessingTask) {
        guard downloadTask != nil else {
            task.setTaskCompleted(success: true)
            return
        }
        continuedTask = task
        task.progress.totalUnitCount = 100
        task.expirationHandler = { [weak self] in
            Task { @MainActor in
                // The system ended it: pause, keep the partial files, resume on return.
                self?.continuedTask = nil
                self?.requestStop(.backgroundTimeUp)
                task.setTaskCompleted(success: false)
            }
        }
        if case .downloading(let progress) = state { updateContinuedTaskProgress(progress) }
    }

    private func updateContinuedTaskProgress(_ fraction: Double?) {
        guard #available(iOS 26.0, *), let task = continuedTask as? BGContinuedProcessingTask,
              let fraction else { return }
        task.progress.completedUnitCount = Int64(fraction * 100)
    }
}

/// Bridges Sapient's download callbacks to Swift; returning `false` from `onProgress` cancels the download.
private final class ProgressListener: DownloadListener, @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private let handler: @Sendable (UInt64, UInt64) -> Void

    init(handler: @escaping @Sendable (UInt64, UInt64) -> Void) {
        self.handler = handler
    }

    var isCancelled: Bool {
        lock.withLock { cancelled }
    }

    func cancel() {
        lock.withLock { cancelled = true }
    }

    func onProgress(downloadedBytes: UInt64, totalBytes: UInt64) -> Bool {
        handler(downloadedBytes, totalBytes)
        return !isCancelled
    }
}
