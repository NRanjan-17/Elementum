import SwiftUI

struct ElementListView: View {
    var elements: [Element]
    var onSelect: (Element) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""

    // Formatter for mass
    let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 4
        return f
    }()

    var filteredElements: [Element] {
        if searchText.isEmpty {
            return elements
        } else {
            return elements.filter {
                $0.element.lowercased().contains(searchText.lowercased()) ||
                $0.symbol.lowercased().contains(searchText.lowercased()) ||
                String($0.id).contains(searchText)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search name, symbol, or ID...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .submitLabel(.done)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal)
                .padding(.top, 10)

                // MARK: - Selection List
                List(filteredElements) { element in
                    Button(action: {
                        onSelect(element)
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            let massString = formatter.string(from: NSNumber(value: element.mass)) ?? ""
                            
                            ElementCellView(
                                element: element.element,
                                symbol: element.symbol,
                                atomicNumber: element.id,
                                atomicMass: massString,
                                block: element.block
                            )
                            .scaleEffect(0.6)
                            .frame(width: 60, height: 60)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(element.element)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
//                                Text("\(massString) u")
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue.opacity(0.8))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Element")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
