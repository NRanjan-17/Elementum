import SwiftUI

struct ElementOfTheDayCard: View {
    let element: Element
    var animation: Namespace.ID
    
    var body: some View {
        NavigationLink {
            ElementDetailView(element: element, animation: animation)
        } label: {
            HStack(spacing: 16) {
                ElementCellView(element: element.element, symbol: element.symbol, atomicNumber: element.id, atomicMass: "\(element.mass)", block: element.block)
                    .scaleEffect(0.7)
                    .frame(width: 90, height: 90)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Element of the Day")
                        .font(.footnote)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    Text(element.element)
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                    Text(element.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding()
            .background(.regularMaterial, in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}
