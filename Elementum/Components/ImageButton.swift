//
//  ImageButton.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 31/01/26.
//

import SwiftUI

struct ImageButton: View {
    let image: String
    let text: String
    var isSelected: Bool = false
    
    // Grab the current device type explicitly
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Detect the device's width class (iPad vs iPhone)
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var body: some View {
        ZStack {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 150)
                .clipped()
                .overlay(
                    Color.black.opacity(0.2)
                )
            
            
            Text(text)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        // Logic: If iPad/Desktop (Regular), use 25. If iPhone (Compact), use 12.5.
        // We also use 'style: .continuous' for that smooth Apple look.
        .clipShape(RoundedRectangle(cornerRadius: sizeClass == .regular ? 25 : 12.5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: sizeClass == .regular ? 25 : 12.5, style: .continuous)
                .stroke(Color.blue, lineWidth: (isSelected && isPad) ? 4 : 0)
        )
        .scaleEffect(isSelected ? 1.0 : 0.98)
        .animation(.spring(), value: isSelected)
    }
}
