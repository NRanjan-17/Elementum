import SwiftUI

struct CombineView: View {
    @State private var selectedElements: [Element?] = [nil, nil]
    @State private var showElementList: Bool = false
    @State private var currentSelectionIndex: Int? = nil
    @State private var numberOfElements: Int = 2
    @State private var result: String? = nil
    @State private var allElements: [Element] = []
    
    private let combinationValidator = CombinationValidator()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    Menu {
                        Button("Two") { updateNumberOfElements(to: 2) }
                        Button("Three") { updateNumberOfElements(to: 3) }
                        Button("Four") { updateNumberOfElements(to: 4) }
                        Button("Five") { updateNumberOfElements(to: 5) }
                    } label: {
                        HStack {
                            Text("Select number of Elements:")
                            Text("\(numberOfElements)")
                                .bold()
                        }
                        .padding()
                        .frame(width: 350)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Element Selection Grid
                    VStack(spacing: 30) {
                        ForEach(0..<numberOfElements, id: \.self) { index in
                            Button(action: {
                                currentSelectionIndex = index
                                showElementList.toggle()
                            }) {
                                if let element = selectedElements[index] {
                                    ElementCellView(element: element.element, symbol: element.symbol, atomicNumber: element.id, atomicMass: "\(element.mass)")
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(Color.gray.opacity(0.3))
                                        .overlay(
                                            Text("+")
                                                .font(.largeTitle)
                                                .foregroundColor(.blue)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Combine Button
                    Button(action: {
                        result = validateCombination()
                    }) {
                        Text("Combine")
                            .font(.title2)
                            .bold()
                            .frame(width: 200)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)

                    // Result Display
                    if let result = result {
                        Text(result)
                            .font(.title2)
                            .bold()
                            .padding()
                            .frame(width: 350)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Combine Elements")
        }
        .sheet(isPresented: $showElementList) {
            ElementListView(elements: allElements) { selectedElement in
                if let index = currentSelectionIndex {
                    selectedElements[index] = selectedElement
                }
            }
        }
        .onAppear {
            loadElements()
            
        }
    }

    private func updateNumberOfElements(to count: Int) {
        numberOfElements = count
        selectedElements = Array(selectedElements.prefix(count)) + Array(repeating: nil, count: max(0, count - selectedElements.count))
    }

    private func validateCombination() -> String {
        let validElements = selectedElements.compactMap { $0 }
        return combinationValidator.validate(elements: validElements)
    }

    private func loadElements() {
        let elementModel = ElementModel()
        if let loadedElements: [Element] = elementModel.load("Elements.json") {
            allElements = loadedElements
        }
    }
}

#Preview {
    CombineView()
}
