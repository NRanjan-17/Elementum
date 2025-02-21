import SwiftUI

struct Elements: View {
    
    @Namespace var animation
    @State private var selected: Element?
    @State private var listMode = false
    var elements: [Element] = ElementModel().load("Elements.json")
    let formatter = NumberFormatter()
    
    init() {
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 4
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyHStack(alignment: .top) {
                ForEach(1..<18) { row in
                    LazyVStack(alignment: .leading) {
                        ForEach(1..<10) { column in
                            // Display matching element based on column and row, otherwise display blank space
                            if let element = elements.first(where: { $0.column == column && $0.row == row }) {
                                let formattedMass = formatter.string(from: NSNumber(value: element.mass))
                                
                                Button {
                                    selected = element
                                } label: {
                                    ElementCellView(element: element.element, symbol: element.symbol, atomicNumber: element.id, atomicMass: formattedMass!)
                                        .contextMenu {
                                            Button {
                                                UIPasteboard.general.string = element.element
                                            } label: {
                                                Label(element.element, systemImage: "document.on.document")
                                            }
                                            
                                            Button {
                                                UIPasteboard.general.string = "\(formattedMass!) u"
                                            } label: {
                                                Label("\(formattedMass!) u", systemImage: "document.on.document")
                                            }
                                        }
                                }
                                .matchedTransitionSource(id: element.id, in: animation)
                            } else {
                                Rectangle()
                                    .frame(width: 100, height: 100)
                                    .opacity(0)
                            }
                            
                            // Add spacing in-between columns 7 and 8
                            if column == 7 {
                                Rectangle()
                                    .opacity(0)
                            }
                        }
                    }
                    
                    // Add spacing in-between rows 3 and 4
                    if row == 3 {
                        Rectangle()
                            .opacity(0)
                    }
                }
            }
            .sheet(item: $selected) { element in
                // Allows for zoom transition to ElementDetailView when tapping an element
                ElementDetailView(element: element, animation: animation)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentMargins(10, for: .scrollContent)
        .scrollIndicators(.hidden)
        .navigationTitle("Periodic Table")
    }
}

