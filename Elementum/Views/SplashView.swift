import SwiftUI

/// Launch splash: the element-cell logo builds itself, then the wordmark
/// rises. About 1.4 s in all, inside the
/// 2 s the app keeps the splash on screen.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tile = 0.0
    @State private var symbol = 0.0
    @State private var detail = 0.0
    @State private var titleVisible = false

    var body: some View {
        ZStack {
            Rectangle().fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ElementumLogo(size: 168,
                              tileProgress: tile,
                              symbolProgress: symbol,
                              detailProgress: detail)
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
        .onAppear(perform: play)
    }

    /// Each step is its own animation with a delay, so the steps overlap
    /// smoothly without sleeping between them.
    private func play() {
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.35)) {
                tile = 1; symbol = 1; detail = 1; titleVisible = true
            }
            return
        }
        // 1. The cell springs up.
        withAnimation(.spring(duration: 0.6, bounce: 0.35)) { tile = 1 }
        // 2. "El" drops in and comes into focus.
        withAnimation(.spring(duration: 0.55, bounce: 0.2).delay(0.22)) { symbol = 1 }
        // 3. Number and name settle in.
        withAnimation(.easeOut(duration: 0.45).delay(0.42)) { detail = 1 }
        // 4. The wordmark rises.
        withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.62)) { titleVisible = true }
    }
}

#Preview {
    SplashView()
}
