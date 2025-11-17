import SwiftUI

struct ElementListView: View {
    var elements: [Element]
    var onSelect: (Element) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""

    var filteredElements: [Element] {
        if searchText.isEmpty {
            return elements
        } else {
            return elements.filter { 
                $0.element.lowercased().contains(searchText.lowercased()) || 
                $0.symbol.lowercased().contains(searchText.lowercased()) 
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray.opacity(0.6))

                    TextField("Search Elements...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                }
                .padding(12.5)
                .background(Color(.systemGray5).opacity(0.75))
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top, 10)

                List(filteredElements) { element in
                    Button(action: {
                        onSelect(element)
                        dismiss()
                    }) {
                        HStack {
                            Text("\(element.symbol)")
                                .font(.headline)
                                .frame(width: 50)
                            Text(element.element)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Select Elements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
