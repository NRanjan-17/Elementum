import SwiftUI

/// Shown in place of the Combine screen until the on-device model has been downloaded.
struct ModelDownloadView: View {
    @EnvironmentObject var modelManager: ModelManager
    
    private var sizeText: String {
        guard let bytes = modelManager.downloadSizeBytes else { return "about 1 GB" }
        return bytes.formatted(.byteCount(style: .file))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "atom")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, isActive: isDownloading)
                    .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text("Set Up Combine")
                        .font(.title)
                        .bold()
                    Text("Combine predicts reactions with an AI model that runs privately on your device. Download it once (\(sizeText)) and it works offline afterwards.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                statusSection
            }
            .padding(24)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Combine")
            .navigationBarTitleDisplayMode(.inline)
            .task { await modelManager.loadDownloadSize() }
        }
    }
    
    private var isDownloading: Bool {
        if case .downloading = modelManager.state { return true }
        return false
    }
    
    @ViewBuilder
    private var statusSection: some View {
        switch modelManager.state {
        case .notDownloaded, .ready:
            Button("Download Model", systemImage: "arrow.down.circle.fill", action: modelManager.download)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            Text("Wi-Fi is recommended.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            
        case .downloading(let progress):
            VStack(spacing: 12) {
                if let progress {
                    ProgressView(value: progress)
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    ProgressView()
                    Text("Starting download…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button("Cancel", role: .cancel, action: modelManager.cancelDownload)
            }
            
        case .failed(let message):
            VStack(spacing: 12) {
                Label("Download failed", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Again", systemImage: "arrow.clockwise", action: modelManager.download)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ModelDownloadView()
        .environmentObject(ModelManager())
}
