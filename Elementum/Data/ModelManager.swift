import SwiftUI
import Sapient

/// Tracks whether the on-device language model has been downloaded, and downloads it on request.
@MainActor
final class ModelManager: ObservableObject {
    
    enum State: Equatable {
        case notDownloaded
        case downloading(progress: Double?)
        case ready
        case failed(String)
    }
    
    /// Qwen2.5-1.5B-Instruct, Q4_K_M (~1 GB). SAPIENT's docs recommend the Q4 build on phones.
    nonisolated static let modelAlias = "qwen2.5-1.5b-q4"
    private static let downloadedKey = "sapientModelDownloaded"
    
    @Published private(set) var state: State
    @Published private(set) var downloadSizeBytes: UInt64?
    
    private var downloadTask: Task<Void, Never>?
    private var listener: ProgressListener?
    
    init() {
        // Weights live in Caches so the OS can reclaim them and uninstall removes them.
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            setCacheDir(path: caches.path)
        }
        state = UserDefaults.standard.bool(forKey: Self.downloadedKey) ? .ready : .notDownloaded
    }
    
    func loadDownloadSize() async {
        guard downloadSizeBytes == nil else { return }
        downloadSizeBytes = try? await modelDownloadSize(model: Self.modelAlias)
    }
    
    func download() {
        guard downloadTask == nil else { return }
        state = .downloading(progress: nil)
        
        let listener = ProgressListener { [weak self] downloaded, total in
            Task { @MainActor in
                guard let self, case .downloading = self.state else { return }
                self.state = .downloading(progress: total > 0 ? Double(downloaded) / Double(total) : nil)
            }
        }
        self.listener = listener
        
        downloadTask = Task {
            do {
                try await downloadModel(model: Self.modelAlias, listener: listener)
                if listener.isCancelled {
                    state = .notDownloaded
                } else {
                    UserDefaults.standard.set(true, forKey: Self.downloadedKey)
                    state = .ready
                }
            } catch {
                state = listener.isCancelled ? .notDownloaded : .failed(error.localizedDescription)
            }
            downloadTask = nil
            self.listener = nil
        }
    }
    
    func cancelDownload() {
        listener?.cancel()
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
