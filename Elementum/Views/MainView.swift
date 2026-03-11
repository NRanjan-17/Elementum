import SwiftUI

struct MainView: View {
    
    @State var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeView()
            }
            Tab("Combine", systemImage: "atom", value: 1) {
                CombineView()
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
}
