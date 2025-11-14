import SwiftUI

struct FinderView: View {

    @Namespace var animation
    @State private var selected: Element?
    @State private var listMode = false
    @State private var searchText = ""
    @State private var randomElements: [Element] = []
    
    var elements: [Element] = ElementModel().load("Elements.json")
    
    let formatter = NumberFormatter()
    
    init() {
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
    }
    
    var filteredElements: [Element] {
        if searchText.isEmpty {
            return randomElements
        } else {
            return elements.filter {
                $0.element.lowercased().contains(searchText.lowercased()) ||
                String($0.id).contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - Search Bar
                TextField("Search elements...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // MARK: - List of Elements
                List {
                    ForEach(filteredElements) { element in
                        
                        let formattedMass = formatter.string(from: NSNumber(value: element.mass))!
                        
                        NavigationLink(
                            destination: ElementDetailView(element: element, animation: animation)
                        ) {
                            HStack {
                                Text("\(element.id)")
                                    .frame(minWidth: 35, alignment: .leading)
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(element.element)
                                        
                                        Spacer()
                                        
                                        VStack {
                                            Text(element.symbol)
                                            Text("\(formattedMass) u")
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .matchedTransitionSource(id: element.id, in: animation)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = element.element
                                } label: {
                                    Label(element.element, systemImage: "document.on.document")
                                }
                                
                                Button {
                                    UIPasteboard.general.string = "\(formattedMass) u"
                                } label: {
                                    Label("\(formattedMass) u", systemImage: "document.on.document")
                                }
                            }
                        }
                    }
                }
                // IMPORTANT: Dismiss keyboard correctly without blocking taps
                .scrollDismissesKeyboard(.immediately)
                
                .navigationTitle("Finder")
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .contentMargins(10, for: .scrollContent)
                .scrollIndicators(.hidden)
                
                .onAppear {
                    randomElements = Array(elements.shuffled().prefix(5))
                }
            }
        }
    }
}
