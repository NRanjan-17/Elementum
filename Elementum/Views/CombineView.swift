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
                VStack(spacing: 25) {
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

                    VStack(spacing: 20) {
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

                    Button(action: {
                        result = validateCombination()
                    }) {
                        Text("Combine")
                            .font(.title2)
                            .bold()
                            .frame(width: 250)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12.5)
                    }
                    .padding(.horizontal)

                    if let result = result {
                        Text(result)
                            .font(.title2)
                            .bold()
                            .padding()
                            .frame(width: 285)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(12.5)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Combine Elements")
            .onAppear {
                if allElements.isEmpty {
                    loadElements()
                }
            }
        }
        .sheet(isPresented: $showElementList) {
            ElementListView(elements: allElements) { selectedElement in
                if let index = currentSelectionIndex {
                    selectedElements[index] = selectedElement
                    selectedElements = selectedElements.map { $0 }
                }
            }
        }
    }

    private func updateNumberOfElements(to count: Int) {
        numberOfElements = count
        selectedElements = Array(selectedElements.prefix(count)) + Array(repeating: nil, count: max(0, count - selectedElements.count))
    }

    private func validateCombination() -> String {
        let validElements = selectedElements.compactMap { $0 }
        guard validElements.count == numberOfElements else {
            return "Please select \(numberOfElements) elements."
        }

        return combinationValidator.validate(elements: validElements) ?? "No valid combination found"
    }

    private func loadElements() {
        guard let url = Bundle.main.url(forResource: "Elements", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decodedElements = try JSONDecoder().decode([Element].self, from: data)
            
            DispatchQueue.main.async {
                self.allElements = decodedElements
                self.selectedElements = Array(repeating: nil, count: self.numberOfElements)
            }
        } catch {
        }
    }
}

#Preview {
    CombineView()
}
