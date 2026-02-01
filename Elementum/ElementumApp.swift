import SwiftUI

@main
struct ElementumApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var elementStore = ElementStore()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(elementStore)
                .onAppear {
                    // Default orientation for entire app = portrait
                    OrientationManager.shared.allowed = .portrait
                }
        }
        .modelContainer(for: ChemicalEntity.self)
    }
}
