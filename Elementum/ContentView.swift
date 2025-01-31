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
        }
    }
}
#Preview {
    ContentView()
}
