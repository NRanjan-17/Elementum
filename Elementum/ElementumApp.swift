import SwiftUI

@main
struct ElementumApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var elementStore = ElementStore()
    @StateObject private var modelManager = ModelManager()
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environmentObject(elementStore)
                    .environmentObject(modelManager)
                if showSplash {
                    SplashView()
                        .transition(.scale(scale: 1.15).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
            }
                .onAppear {
                    // Default orientation for entire app = portrait
                    OrientationManager.shared.allowed = .portrait
                }
        }
        .modelContainer(for: ChemicalEntity.self)
    }
}
