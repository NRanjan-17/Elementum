//
//  CompoundCreatorView.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 31/01/26.
//

import SwiftUI
import SwiftData

struct CompoundCreatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var elementStore: ElementStore
    
    @State private var formulaParts: [FormulaPart] = []
    @State private var compoundName: String = ""
    @State private var netCharge: Int = 0
    @State private var showElementPicker: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // --- Section 1: The Preview ---
                Section(header: Text("Compound Preview")) {
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            // Dynamic Formula Display
                            Text(constructFormula().chemicalFormatting())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                            
                            if !compoundName.isEmpty {
                                Text(compoundName)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Name your compound")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                
                // --- Section 2: Building Blocks ---
                Section(header: Text("Composition")) {
                    if formulaParts.isEmpty {
                        Text("No elements added yet.")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    ForEach($formulaParts) { $part in
                        HStack {
                            Text(part.symbol)
                                .font(.title3)
                                .bold()
                                .frame(width: 50, alignment: .leading)
                            
                            Divider()
                            
                            Stepper("Qty: \(part.count)", value: $part.count, in: 1...99)
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                deletePart(id: part.id)
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .foregroundStyle(Color.red)
                            }
                        }
                    }
                    
                    Button(action: { showElementPicker = true }) {
                        Label("Add Element", systemImage: "plus.circle.fill")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)
                    }
                }
                
                // --- Section 3: Ionization ---
                Section(header: Text("Ionization / Charge")) {
                    HStack {
                        Text("Net Charge:")
                        Spacer()
                        Text("\(netCharge > 0 ? "+" : "")\(netCharge)")
                            .bold()
                            .foregroundColor(netCharge == 0 ? .primary : (netCharge > 0 ? .green : .red))
                    }
                    Stepper("Adjust Charge", value: $netCharge, in: -8...8)
                        .labelsHidden()
                }
                
                // --- Section 4: Save ---
                Section {
                    TextField("Compound Name (e.g. Sulfuric Acid)", text: $compoundName)
                        .textInputAutocapitalization(.words)
                }
            }
            .navigationTitle("Compound Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCompound() }
                        .disabled(formulaParts.isEmpty || compoundName.isEmpty)
                }
            }
            // Use the shared store here
            .sheet(isPresented: $showElementPicker) {
                ElementPickerView(elements: elementStore.elements) { selectedElement in
                    addOrUpdatePart(symbol: selectedElement.symbol)
                }
            }
        }
    }
    
    // MARK: - Logic Helpers
    func addOrUpdatePart(symbol: String) {
        // If element already exists, just increase count
        if let index = formulaParts.firstIndex(where: { $0.symbol == symbol }) {
            formulaParts[index].count += 1
        } else {
            formulaParts.append(FormulaPart(symbol: symbol, count: 1))
        }
    }
    
    func deletePart(id: UUID) {
        formulaParts.removeAll { $0.id == id }
    }
    
    func constructFormula() -> String {
        var formula = ""
        for part in formulaParts {
            formula += part.symbol
            if part.count > 1 { formula += "\(part.count)" }
        }
        
        if netCharge > 0 {
            formula += String(repeating: "+", count: netCharge)
        } else if netCharge < 0 {
            formula += String(repeating: "-", count: abs(netCharge))
        }
        return formula
    }
    
    func saveCompound() {
        let finalFormula = constructFormula()
        let newEntity = ChemicalEntity(
            formula: finalFormula,
            name: compoundName,
            type: netCharge != 0 ? .ion : .compound,
            charge: netCharge
        )
        
        modelContext.insert(newEntity)
        try? modelContext.save() // Quietly save
        dismiss()
    }
}

#Preview {
    CompoundCreatorView()
        .environmentObject(ElementStore())
}
