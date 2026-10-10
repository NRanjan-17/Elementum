import SwiftUI

struct MainView: View {
    
    @State var selectedTab = 0
    @EnvironmentObject var modelManager: ModelManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeView()
            }
            Tab("Combine", systemImage: "atom", value: 1) {
                if modelManager.state == .ready {
                    CombineView()
                } else {
                    ModelDownloadView()
                }
            }
            Tab("Finder", systemImage: "magnifyingglass", value: 2) {
                FinderView()
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainView()
        .environmentObject(ElementStore())
        .environmentObject(ModelManager())
}
