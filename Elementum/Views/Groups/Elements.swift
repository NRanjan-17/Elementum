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
                ForEach(1..<19, id: \.self) { row in
                    elementGrid(for: row)
                    
                    if row == 3 {
                        emptyCell()
                    }
                }
            }
        }
        .allowLandscape()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentMargins(10, for: .scrollContent)
        .scrollIndicators(.hidden)
        .navigationTitle("Periodic Table")
    }
    
    private func elementGrid(for row: Int) -> some View {
        LazyVStack(alignment: .leading) {
            ForEach(1..<10) { column in
                if let element = elements.first(where: { $0.column == column && $0.row == row }) {
                    elementButton(for: element)
                } else {
                    emptyCell()
                }
                
                if column == 7 { emptyCell() }
            }
        }
    }
    
    private func elementButton(for element: Element) -> some View {
        let formattedMass = formatter.string(from: NSNumber(value: element.mass)) ?? "N/A"
        
        let isSelected = Binding<Bool>(
            get: { selected?.id == element.id },
            set: { if !$0 { selected = nil } }
        )
        
        return Button {
            selected = element
        } label: {
            ElementCellView(
                element: element.element,
                symbol: element.symbol,
                atomicNumber: element.id,
                atomicMass: formattedMass,
                block: element.block
            )
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
        .matchedTransitionSource(id: element.id, in: animation)
        .popover(isPresented: isSelected, attachmentAnchor: .rect(.bounds)) {
            ElementDetailView(element: element, animation: animation)
                .frame(minWidth: 400, minHeight: 550)
                .presentationCompactAdaptation(.sheet)
        }
    }
    
    private func emptyCell() -> some View {
        Rectangle()
            .frame(width: 100, height: 100)
            .opacity(0)
    }
}
