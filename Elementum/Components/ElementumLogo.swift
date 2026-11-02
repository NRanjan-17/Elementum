//
//  ElementumLogo.swift
//  Elementum
//

import SwiftUI

/// The Elementum mark drawn in SwiftUI: an element cell with atomic number 1,
/// the symbol "El" and the name underneath, matching the app icon.
///
/// Each part is a separate view so the splash can animate them one by one.
/// `progress` values run from 0 (hidden) to 1 (in place).
struct ElementumLogo: View {
    var size = 180.0
    var tileProgress = 1.0
    var symbolProgress = 1.0
    var detailProgress = 1.0

    /// Same navy and magenta as the icon's layers (magenta is from the Periodic Table card).
    static let ink = Color(red: 0.06, green: 0.13, blue: 0.29)
    static let accent = Color(red: 0.749, green: 0.165, blue: 0.51)

    private var corner: Double { size * 0.2237 }   // iOS app icon corner ratio

    var body: some View {
        ZStack {
            tile
            number
            symbol
            name
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: corner, style: .continuous))
        .scaleEffect(0.7 + 0.3 * tileProgress)
        .opacity(Double(min(tileProgress * 1.6, 1)))
        .accessibilityElement()
        .accessibilityLabel("Elementum")
    }

    // MARK: Parts

    @ViewBuilder private var tile: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        // Always an opaque white cell, so the navy type reads in light and dark mode.
        let cell = shape.fill(.white)
        if #available(iOS 26.0, *) {
            // Liquid Glass over the white cell: edge light and refraction, like the icon.
            cell.glassEffect(.regular, in: shape)
        } else {
            cell.overlay(shape.strokeBorder(.black.opacity(0.06), lineWidth: 1))
        }
    }

    private var number: some View {
        Text("1")
            .font(.system(size: size * 0.117, weight: .semibold))
            .foregroundStyle(Self.accent)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.leading, size * 0.165)
            .padding(.top, size * 0.155)
            .opacity(Double(detailProgress))
    }

    private var symbol: some View {
        Text("El")
            .font(.system(size: size * 0.49, weight: .bold))
            .tracking(-size * 0.014)
            .foregroundStyle(Self.ink)
            // Drops into place and comes into focus.
            .offset(y: (1 - symbolProgress) * size * 0.12 - size * 0.01)
            .blur(radius: (1 - symbolProgress) * size * 0.05)
            .opacity(Double(symbolProgress))
    }

    private var name: some View {
        Text("Elementum")
            .font(.system(size: size * 0.09, weight: .semibold))
            // Letters settle in from wide spacing.
            .tracking(size * 0.001 + (1 - detailProgress) * size * 0.012)
            .foregroundStyle(Self.accent)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, size * 0.135)
            .opacity(Double(detailProgress))
    }

}

#Preview {
    ElementumLogo()
        .padding(40)
        .background(Color.black)
}
