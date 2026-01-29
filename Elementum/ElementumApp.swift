import SwiftUI

@main
struct ElementumApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    // Default orientation for entire app = portrait
                    OrientationManager.shared.allowed = .portrait
                }
        }
    }
}
