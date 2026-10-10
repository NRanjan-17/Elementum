import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var logoRevealed = false
    @State private var titleVisible = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    // The logo opens up from its centre like an iris.
                    .mask {
                        Circle()
                            .scale(logoRevealed || reduceMotion ? 1 : 0)
                    }
                    .scaleEffect(logoRevealed || reduceMotion ? 1 : 0.6)
                    .rotationEffect(.degrees(logoRevealed || reduceMotion ? 0 : -90))
                    .opacity(logoRevealed ? 1 : 0)
                    .accessibilityHidden(true)
                
                Text("Elementum")
                    .font(.largeTitle)
                    .bold()
                    .opacity(titleVisible ? 1 : 0)
                    .offset(y: titleVisible || reduceMotion ? 0 : 12)
            }
        }
        .task {
            if reduceMotion {
                withAnimation(.easeIn(duration: 0.4)) {
                    logoRevealed = true
                    titleVisible = true
                }
                return
            }
            withAnimation(.spring(duration: 0.9, bounce: 0.3)) { logoRevealed = true }
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeOut(duration: 0.6)) { titleVisible = true }
        }
    }
}

#Preview {
    SplashView()
}
