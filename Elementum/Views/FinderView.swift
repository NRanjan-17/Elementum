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
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search elements...", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal)
                .padding(.top, 8)
                
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
                                        
                                        VStack(spacing: 2) {
                                            Text(element.symbol)
                                            Text("\(formattedMass) u")
                                        }
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .matchedTransitionSource(id: element.id, in: animation)
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.horizontal)
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Finder")
            .background(Color(.systemBackground).ignoresSafeArea())
            .onAppear {
                randomElements = Array(elements.shuffled().prefix(5))
            }
        }
    }
}
