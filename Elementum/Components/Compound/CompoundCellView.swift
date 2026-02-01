//
//  CompoundCellView.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import SwiftUI

struct CompoundCellView: View {
    let symbol: String
    let name: String
    let charge: Int
    
    private let beige = Color(red: 0.93, green: 0.88, blue: 0.76)
    
    var body: some View {
        VStack {
            HStack {
                Text(charge > 0 ? "+\(charge)" : "\(charge)")
                    .font(.system(size: 12, weight: .bold))
                    .opacity(charge == 0 ? 0 : 1)
                    .offset(x: 60)
                Spacer()
            }
            
            Text(symbol)
                .fontWeight(.bold)
                .font(.system(size: 35))
                .minimumScaleFactor(0.4)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Text(name)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .opacity(0.7)
        }
        .foregroundStyle(.black)
        .padding(10)
        .frame(width: 100, height: 100)
        .background(beige.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 15.0))
    }
}

#Preview {
    HStack {
        CompoundCellView(symbol: "H₂O", name: "Water", charge: 0)
        CompoundCellView(symbol: "SO₄²⁻", name: "Sulfate", charge: -2)
    }
    .padding()
}
