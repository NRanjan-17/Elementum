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
    var subtitle: String? = nil
    var isSelected: Bool = false
    
    // Grab the current device type explicitly
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Detect the device's width class (iPad vs iPhone)
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private var cornerRadius: CGFloat { sizeClass == .regular ? 25 : 20 }
    
    var body: some View {
        // Color.clear sets the card's shape; the image sits in an overlay so
        // scaledToFill can't push the layout wider than the container.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: sizeClass == .regular ? 200 : 160)
            .overlay {
                Image(decorative: image)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                // Darkens only the bottom so the text stays legible
                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(.title3)
                        .bold()
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.white.secondary)
                    }
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(16)
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(12)
            }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.accentColor, lineWidth: (isSelected && isPad) ? 4 : 0)
            )
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .animation(.spring(), value: isSelected)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            .accessibilityHint(subtitle ?? "")
    }
}
