import SwiftUI
import SwiftData

struct CombineView: View {
    @EnvironmentObject var elementStore: ElementStore
    @Query(sort: \ChemicalEntity.name) private var savedCompounds: [ChemicalEntity]
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    @State private var reactionModel = ReactionModel()
    @State private var reactants: [ReactantWrapper] = []
    @State private var activeSheet: ActiveSheet? = nil
    
    @State private var isPredicting = false
    @State private var result: String?
    
    @State private var showHelp = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        Group {
            if sizeClass == .regular {
                ipadLayout
            } else {
                iphoneLayout
            }
        }
        .sheet(isPresented: $showHelp) {
            CombineHelpView()
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.thinMaterial)
        }
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
    
    // MARK: - iPad Layout
    var ipadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List {
                Section("Add Ingredients") {
                    Button(action: { activeSheet = .elementPicker }) {
                        Label("Add Element", systemImage: "atom")
                    }
                    Button(action: { activeSheet = .compoundPicker }) {
                        Label("Add Compound", systemImage: "flask")
                    }
                    Button(action: { activeSheet = .compoundCreator }) {
                        Label("Create Compound", systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                
                if !reactants.isEmpty {
                    Section("Ingredients") {
                        ForEach(reactants) { wrapper in
                            HStack(spacing: 10) {
                                if wrapper.quantity > 1 {
                                    Text("\(wrapper.quantity)x")
                                        .font(.title3.bold())
                                        .foregroundStyle(.secondary)
                                        .onTapGesture { activeSheet = .quantityEditor(wrapper.id) }
                                }
                                
                                reactantPreview(for: wrapper)
                                    .scaleEffect(0.6)
                                    .frame(width: 60, height: 60)
                                    .onTapGesture { activeSheet = .quantityEditor(wrapper.id) }
                                
                                Text(wrapper.symbol)
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button(role: .destructive) {
                                    withAnimation { reactants.removeAll { $0.id == wrapper.id }; result = nil }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ingredients")
        } detail: {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    if isPredicting {
                        VStack(spacing: 15) {
                            ProgressView().scaleEffect(1.5)
                            Text("Simulating Reaction...").font(.headline).foregroundColor(.secondary)
                        }
                    } else if let result {
                        resultView(result: result)
                    } else {
                        ContentUnavailableView("Combine Elements", systemImage: "flask.fill", description: Text("Add elements to start."))
                    }
                    
                    Spacer()
                    
                    Button(action: runPrediction) {
                        HStack { Image(systemName: "wand.and.stars"); Text("Combine") }
                            .font(.title3.bold()).foregroundColor(.white).frame(width: 200, height: 60)
                            .background(reactants.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor).cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .disabled(reactants.isEmpty || isPredicting)
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationTitle("Combine Elements")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: {
                        Image(systemName: "info.circle").font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
    }
    
    // MARK: - iPhone Layout
    var iphoneLayout: some View {
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
                                        .onTapGesture { activeSheet = .quantityEditor(wrapper.id) }
                                }
                                
                                ZStack(alignment: .topTrailing) {
                                    reactantPreview(for: wrapper)
                                        .scaleEffect(0.7)
                                        .frame(width: 70, height: 70)
                                        .onTapGesture { activeSheet = .quantityEditor(wrapper.id) }
                                    
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
                    .padding([.leading, .trailing], 25)
                Spacer()
                
                if isPredicting {
                    VStack(spacing: 15) {
                        ProgressView().scaleEffect(1.5)
                        Text("Simulating Reaction...").font(.headline).foregroundColor(.secondary)
                    }
                } else if let result {
                    resultView(result: result)
                } else {
                    ContentUnavailableView("Combine Elements", systemImage: "flask.fill", description: Text("Add elements to start."))
                }
                Spacer()
                
                Button(action: runPrediction) {
                    HStack { Image(systemName: "wand.and.stars"); Text("Combine") }
                        .font(.title3.bold()).foregroundColor(.white).frame(width: 150,height: 55)
                        .background(reactants.isEmpty ? Color.gray.opacity(0.5) : Color.accentColor).cornerRadius(15).padding()
                }
                .disabled(reactants.isEmpty || isPredicting)
            }
            .navigationTitle("Combine Elements")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: {
                        Image(systemName: "info.circle").font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
    }
    
    // MARK: - Shared Components
    
    @ViewBuilder
    func reactantPreview(for wrapper: ReactantWrapper) -> some View {
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
    }
    
    @ViewBuilder
    func resultView(result: String) -> some View {
        VStack(spacing: 15) {
            Text("Reaction Product").font(.caption).textCase(.uppercase).foregroundColor(.secondary)
            
            // Equation Box
            Text(result.components(separatedBy: "DESCRIPTION:").first?.replacingOccurrences(of: "EQUATION:", with: "") ?? result)
                .font(.system(size: 24, weight: .bold))
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
