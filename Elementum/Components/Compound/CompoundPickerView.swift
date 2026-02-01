//
//  CompoundPickerView.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import SwiftUI
import SwiftData

struct CompoundPickerView: View {
    let compounds: [ChemicalEntity]
    var onSelect: (ChemicalEntity) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showResetAlert = false
    
    var filteredCompounds: [ChemicalEntity] {
        if searchText.isEmpty {
            return compounds
        } else {
            return compounds.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.formula.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Search compounds...", text: $searchText).autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                List {
                    ForEach(filteredCompounds) { item in
                        Button(action: {
                            onSelect(item)
                            dismiss()
                        }) {
                            HStack(spacing: 16) {
                                
                                CompoundCellView(
                                    symbol: item.computedFormula,
                                    name: item.name,
                                    charge: item.charge
                                )
                                .scaleEffect(0.65)
                                .frame(width: 60, height: 60)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteCompound)
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Select Compound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Text("Reset")
                            .foregroundColor(.red)
                    }
                    .disabled(compounds.isEmpty)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Reset Compounds?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllCompounds()
                }
            } message: {
                Text("Are you sure you want to delete all created compounds? This action cannot be undone.")
            }
            .overlay {
                if compounds.isEmpty {
                    ContentUnavailableView {
                        Label("No Compounds", systemImage: "flask")
                    } description: {
                        Text("Create a new compound from the Add menu.")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func deleteCompound(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredCompounds[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
    
    private func deleteAllCompounds() {
        for compound in compounds {
            modelContext.delete(compound)
        }
        try? modelContext.save()
    }
}
