import SwiftUI

/// Launch splash: the element-cell logo builds itself, then a band of light
/// sweeps across it and the wordmark rises. About 1.4 s in all, inside the
/// 2 s the app keeps the splash on screen.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tile: CGFloat = 0
    @State private var symbol: CGFloat = 0
    @State private var detail: CGFloat = 0
    @State private var shine: CGFloat = 0
    @State private var titleVisible = false

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ElementumLogo(size: 168,
                              tileProgress: tile,
                              symbolProgress: symbol,
                              detailProgress: detail,
                              shineProgress: shine)
                    .shadow(color: .black.opacity(0.12), radius: 24, y: 12)

                VStack(spacing: 6) {
                    Text("Elementum")
                        .font(.largeTitle.bold())
                    Text("Chemistry, made simple.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible || reduceMotion ? 0 : 14)
            }
        }
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.35)) {
                tile = 1; symbol = 1; detail = 1; titleVisible = true
            }
            return
        }
        // 1. The cell springs up.
        withAnimation(.spring(duration: 0.6, bounce: 0.35)) { tile = 1 }
        try? await Task.sleep(for: .seconds(0.22))
        // 2. "El" drops in and comes into focus.
        withAnimation(.spring(duration: 0.55, bounce: 0.2)) { symbol = 1 }
        try? await Task.sleep(for: .seconds(0.2))
        // 3. Number and name settle in.
        withAnimation(.easeOut(duration: 0.45)) { detail = 1 }
        try? await Task.sleep(for: .seconds(0.2))
        // 4. Light sweeps across, and the wordmark rises.
        withAnimation(.easeInOut(duration: 0.7)) { shine = 1 }
        withAnimation(.spring(duration: 0.6, bounce: 0.2)) { titleVisible = true }
    }
}

#Preview {
    SplashView()
}
