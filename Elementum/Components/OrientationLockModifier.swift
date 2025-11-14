//
//  OrientationLockModifier.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 14/11/25.
//

import SwiftUI

struct OrientationLock: ViewModifier {
    let mode: UIInterfaceOrientationMask
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                OrientationManager.shared.allowed = mode
            }
            .onDisappear {
                OrientationManager.shared.allowed = .portrait
            }
    }
}

extension View {
    func allowLandscape() -> some View {
        self.modifier(OrientationLock(mode: .all))
    }
}
