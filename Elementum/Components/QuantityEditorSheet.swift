//
//  QuantityEditorSheet.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import SwiftUI

struct QuantityEditorSheet: View {
    @Binding var reactant: ReactantWrapper
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Adjust Quantity")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top)
            
            HStack(spacing: 30) {
                Text(reactant.symbol)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.accentColor)
                    .frame(minWidth: 60)
                
                Divider()
                    .frame(height: 50)
                
                HStack(spacing: 15) {
                    Button {
                        if reactant.quantity > 1 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            reactant.quantity -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(reactant.quantity > 1 ? .accentColor : .gray.opacity(0.3))
                    }
                    .disabled(reactant.quantity <= 1)
                    
                    Text("\(reactant.quantity)")
                        .font(.system(size: 32, weight: .bold))
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        if reactant.quantity < 99 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            reactant.quantity += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(20)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}


#Preview {
    StateWrapper()
}

private struct StateWrapper: View {
    @State var item = ReactantWrapper(item: .element(Element(id: 1, element: "Hydrogen", symbol: "H", mass: 1.008, row: 1, column: 1, block: "s", bonds: "", noble: "", description: "")))
    
    var body: some View {
        QuantityEditorSheet(reactant: $item)
    }
}
