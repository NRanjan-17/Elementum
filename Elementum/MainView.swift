import SwiftUI

struct MainView: View {
    
    @State var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            CombineView()
                .tabItem {
                    Label("Combine", systemImage: "atom")
                }
                .tag(1)
            
            FinderView()
                .tabItem {
                    Label("Finder", systemImage: "magnifyingglass")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainView()
}
