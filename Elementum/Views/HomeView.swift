import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var store: ElementStore
    @State private var selectedView: SelectedView?
    @Namespace private var animation
    
    /// Picks the same element all day, changing at midnight.
    private var elementOfTheDay: Element? {
        guard !store.elements.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return store.elements[day % store.elements.count]
    }
    
    var body: some View {
        NavigationSplitView {
            ScrollView {
                VStack(spacing: 24) {
                    if let element = elementOfTheDay {
                        ElementOfTheDayCard(element: element, animation: animation)
                    }
                    ForEach(SelectedView.allCases, id: \.self) {view in
                        NavigationLink(destination: view.destination) {
                            ImageButton(
                                image: view.imageName,
                                text: view.title,
                                subtitle: view.subtitle,
                                isSelected: selectedView == view)
                        }
                        .simultaneousGesture(TapGesture().onEnded({
                            selectedView = view
                        }))
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
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
        .environmentObject(ElementStore())
}
