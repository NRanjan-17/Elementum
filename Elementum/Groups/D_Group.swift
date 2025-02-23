import SwiftUI

struct D_Group: View {
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
            .sheet(item: $selected) { element in
                ElementDetailView(element: element, animation: animation)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .contentMargins(10, for: .scrollContent)
        .scrollIndicators(.hidden)
        .navigationTitle("D Group Elements")
    }

    private func elementGrid(for row: Int) -> some View {
        LazyVStack(alignment: .leading) {
            ForEach(1..<19) { column in
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
        let isDBlock = element.block == "D Block"

        return Button {
            if isDBlock { selected = element }
        } label: {
            ElementCellView(
                element: element.element,
                symbol: element.symbol,
                atomicNumber: element.id,
                atomicMass: formattedMass,
                block: element.block
            )
            .foregroundColor(isDBlock ? .white : .gray)
            .background(isDBlock ? Color.blue : Color.gray.opacity(0.3))
            .cornerRadius(15)
            .opacity(isDBlock ? 1 : 0.5)
            .saturation(isDBlock ? 1 : 0)
        }
        .disabled(!isDBlock)
    }

    private func emptyCell() -> some View {
        Rectangle()
            .frame(width: 100, height: 100)
            .opacity(0)
    }
}

