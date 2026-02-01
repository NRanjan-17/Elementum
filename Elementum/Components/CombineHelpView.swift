//
//  CombineHelpView.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 01/02/26.
//

import SwiftUI

struct CombineHelpView: View {
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack(spacing: 25) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.top, 40)
                    .padding(.bottom, 10)

                Text("Combine Elements")
                    .font(.title2.bold())
                
                Text("Discover new chemical reactions by combining elements and compounds.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    HelpRow(icon: "plus.circle.fill", color: .blue, title: "Add Ingredients", description: "Tap the + button to add elements or compounds.")
                    
                    HelpRow(icon: "testtube.2", color: .orange, title: "Adjust Quantities", description: "Tap the number next to an item to change its quantity.")
                    
                    HelpRow(icon: "wand.and.stars", color: .purple, title: "Combine", description: "Tap the 'Combine' button to simulate the reaction.")
                    
                    HelpRow(icon: "trash.circle.fill", color: .red, title: "Clear", description: "Use the 'Clear Lab' button to reset the view.")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

// Helper View for the rows
struct HelpRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
                
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    CombineHelpView()
}
