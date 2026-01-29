import SwiftUI

struct P_Group: View {
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

                    // Add spacing between rows 3 and 4
                    if row == 3 {
                        emptyCell()
                    }
                }
            }
            .sheet(item: $selected) { element in
                ElementDetailView(element: element, animation: animation)
            }
        }
        .allowLandscape()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentMargins(10, for: .scrollContent)
        .scrollIndicators(.hidden)
        .navigationTitle("P Group Elements")
    }

    private func elementGrid(for row: Int) -> some View {
        LazyVStack(alignment: .leading) {
            ForEach(1..<19) { column in
                if let element = elements.first(where: { $0.column == column && $0.row == row }) {
                    elementButton(for: element)
                } else {
                    emptyCell()
                }

                // Add spacing in-between columns 7 and 8
                if column == 7 { emptyCell() }
            }
        }
    }

    private func elementButton(for element: Element) -> some View {
        let formattedMass = formatter.string(from: NSNumber(value: element.mass)) ?? "N/A"
        let isPBlock = element.block == "P Block"

        return Button {
            if isPBlock { selected = element }
        } label: {
            ElementCellView(
                element: element.element,
                symbol: element.symbol,
                atomicNumber: element.id,
                atomicMass: formattedMass,
                block: element.block
            )
            .foregroundColor(isPBlock ? .white : .gray)
            .background(isPBlock ? Color.blue : Color.gray.opacity(0.3))
            .cornerRadius(15)
            .opacity(isPBlock ? 1 : 0.5)
            .saturation(isPBlock ? 1 : 0)
            
            .matchedGeometryEffect(id: element.id, in: animation)
        }
        .disabled(!isPBlock)
    }

    private func emptyCell() -> some View {
        Rectangle()
            .frame(width: 100, height: 100)
            .opacity(0)
    }
}
