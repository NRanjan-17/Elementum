import SwiftUI

struct ContentView: View {
    
    @State var selectedTab=0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            Text("Combine two chemical elements.")
                .tabItem{
                    Label("Combine", systemImage: "atom" )
                }
                .tag(1)
            
            Text("Find the Elements.")
                .tabItem{
                    Label("Finder", systemImage: "magnifyingglass" )
                }
                .tag(2)
        }
    }
}
#Preview {
    ContentView()
}
