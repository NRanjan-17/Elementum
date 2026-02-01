import SwiftUI
import SwiftData

struct CombineView: View {
    @EnvironmentObject var elementStore: ElementStore
    @Query(sort: \ChemicalEntity.name) private var savedCompounds: [ChemicalEntity]
    
    @State private var reactionModel = ReactionModel()
    @State private var reactants: [ReactantWrapper] = []
    @State private var activeSheet: ActiveSheet? = nil
    
    @State private var isPredicting = false
    @State private var result: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        Menu {
                            Section("Add Existing") {
                                Button("Add Element", systemImage: "atom") { activeSheet = .elementPicker }
                                Button("Add Compound", systemImage: "flask") { activeSheet = .compoundPicker }
                            }
                            Section("Create New") {
                                Button("Create Compound", systemImage: "plus.circle.fill") { activeSheet = .compoundCreator }
                            }
                        } label: {
                            Rectangle().fill(Color.accentColor.opacity(0.3))
                                .frame(width: 70, height: 70)
                                .cornerRadius(15)
                                .overlay(Image(systemName: "plus").font(.title).foregroundColor(.accentColor))
                        }
                        .padding(.trailing, 15)
                        .padding(.leading, 15)
                        
                        ForEach(reactants) { wrapper in
                            HStack(spacing: 4) {
                                
                                if wrapper.quantity > 1 {
                                    Text("\(wrapper.quantity)")
                                        .font(.system(size: 30, weight: .bold))
                                        .foregroundColor(.primary)
                                        .onTapGesture {
                                            activeSheet = .quantityEditor(wrapper.id)
                                        }
                                }
                                
                                ZStack(alignment: .topTrailing) {
                                    Group {
                                        switch wrapper.item {
                                        case .element(let elem):
                                            ElementCellView(
                                                element: elem.element,
                                                symbol: elem.symbol,
                                                atomicNumber: elem.id,
                                                atomicMass: String(format: "%.2f", elem.mass),
                                                block: elem.block
                                            )
                                        case .compound(let comp):
                                            CompoundCellView(
                                                symbol: comp.computedFormula,
                                                name: comp.name,
                                                charge: comp.charge
                                            )
                                        }
                                    }
                                    .scaleEffect(0.7)
                                    .frame(width: 70, height: 70)
                                    .onTapGesture {
                                        activeSheet = .quantityEditor(wrapper.id)
                                    }
                                    
                                    Button {
                                        withAnimation { reactants.removeAll { $0.id == wrapper.id }; result = nil }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.body)
                                            .foregroundStyle(.gray, .white)
                                            .background(Circle().fill(.white))
                                    }
                                    .offset(x: 2, y: -2)
                                }
                                
                                if wrapper.id != reactants.last?.id {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .padding(.horizontal, 8)
                                }
                            }
                            .transition(.scale)
                        }
                    }
                    .padding(.vertical)
                }
                .frame(height: 140)
                
                Divider()
                Spacer()
                
                if isPredicting {
                    VStack(spacing: 15) {
                        ProgressView().scaleEffect(1.5)
                        Text("Simulating Reaction...").font(.headline).foregroundColor(.secondary)
                    }
                } else if let result {
                    VStack(spacing: 15) {
                        Text("Reaction Product").font(.caption).textCase(.uppercase).foregroundColor(.secondary)
                        
                        // Equation Box
                        Text(result.components(separatedBy: "DESCRIPTION:").first?.replacingOccurrences(of: "EQUATION:", with: "") ?? result)
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.green.opacity(0.1)))
                        
                        // Description Text
                        if result.contains("DESCRIPTION:") {
                            Text(result.components(separatedBy: "DESCRIPTION:").last ?? "")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("Clear Lab") {
                            withAnimation { self.result = nil; self.reactants.removeAll() }
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    ContentUnavailableView("Combine Elements", systemImage: "flask.fill", description: Text("Add elements to start."))
                }
                Spacer()
                
                Button(action: runPrediction) {
                    HStack { Image(systemName: "wand.and.stars"); Text("Combine") }
                        .font(.title3.bold()).foregroundColor(.white).frame(width: 200,height: 55)
                        .background(reactants.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor).cornerRadius(15).padding()
                }
                .disabled(reactants.isEmpty || isPredicting)
            }
            .navigationTitle("Combine Elements")
            
            .sheet(item: $activeSheet) { item in
                switch item {
                case .elementPicker:
                    ElementPickerView(elements: elementStore.elements) { element in
                        withAnimation { reactants.append(ReactantWrapper(item: .element(element))); result = nil }
                    }
                case .compoundPicker:
                    CompoundPickerView(compounds: savedCompounds) { compound in
                        withAnimation { reactants.append(ReactantWrapper(item: .compound(compound))); result = nil }
                    }
                case .compoundCreator:
                    CompoundCreatorView()
                    
                case .quantityEditor(let id):
                    if let index = reactants.firstIndex(where: { $0.id == id }) {
                        QuantityEditorSheet(reactant: $reactants[index])
                    } else {
                        Text("Item not found")
                    }
                }
            }
        }
    }
    
    func runPrediction() {
        isPredicting = true
        let inputs = reactants.map { $0.formattedString }
        
        // 🔍 DEBUG PRINT: This will show up in your Xcode Console
        print("--------------------------------------------------")
        print("🧪 AI INPUT SENT: \(inputs)")
        print("--------------------------------------------------")
        
        Task {
            let prediction = await reactionModel.predict(elements: inputs)
            
            // 🔍 DEBUG OUTPUT
            print("--------------------------------------------------")
            print("⚗️ AI OUTPUT RECEIVED: \(prediction)")
            print("--------------------------------------------------")
            
            await MainActor.run { self.result = prediction; self.isPredicting = false }
        }
    }
}

#Preview {
    CombineView()
        .environmentObject(ElementStore())
}
