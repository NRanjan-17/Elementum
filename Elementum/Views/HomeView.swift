import SwiftUI

struct HomeView: View {
    
    @State private var selectedView: SelectedView?
    
    var body: some View {
        NavigationSplitView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30){
                    ForEach(SelectedView.allCases, id: \.self) {view in
                        NavigationLink(destination: view.destination) {
                            ImageButton(
                                image: view.imageName,
                                text: view.title,
                                isSelected: selectedView == view)
                        }
                        .simultaneousGesture(TapGesture().onEnded({
                            selectedView = view
                        }))
                    }
                }
                .padding()
            }
            .navigationTitle("Elementum")
        } detail: {
            if let selectedView {
                selectedView.destination
            } else {
                SelectedView.periodicTable.destination
            }
        }
        .onAppear {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if selectedView == nil {
                    selectedView = .periodicTable
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
