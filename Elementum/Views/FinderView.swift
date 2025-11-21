import SwiftUI

struct FinderView: View {
    
    @Namespace var animation
    @State private var searchText = ""
    @State private var randomElements: [Element] = []
    
    // Load elements using your existing ElementModel
    var elements: [Element] = ElementModel().load("Elements.json")
    
    // Formatter configuration
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
                $0.symbol.lowercased().contains(searchText.lowercased()) ||
                String($0.id).contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - Custom Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search name, symbol, or ID...", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
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
                .padding(.top, 8)
                .padding(.bottom, 10)
                
                // MARK: - Element List
                List {
                    ForEach(filteredElements) { element in
                        NavigationLink(value: element) {
                            HStack(spacing: 16) {
                                // 1. Reusing existing ElementCellView
                                let massString = formatter.string(from: NSNumber(value: element.mass)) ?? ""
                                
                                ElementCellView(
                                    element: element.element,
                                    symbol: element.symbol,
                                    atomicNumber: element.id,
                                    atomicMass: massString,
                                    block: element.block
                                )
                                .scaleEffect(0.65)
                                .frame(width: 70, height: 70)
                                .matchedTransitionSource(id: element.id, in: animation)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(element.element)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(massString) u")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.immediately)
                .navigationDestination(for: Element.self) { element in
                    ElementDetailView(element: element, animation: animation)
                }
            }
            .navigationTitle("Finder")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                if randomElements.isEmpty {
                    randomElements = Array(elements.shuffled().prefix(5))
                }
            }
        }
    }
}
