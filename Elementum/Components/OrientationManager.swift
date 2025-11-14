//
//  OrientationManagere.swift
//  Elementum
//
//  Created by Nalinish Ranjan on 14/11/25.
//

import SwiftUI

class OrientationManager {
    static let shared = OrientationManager()
    var allowed: UIInterfaceOrientationMask = .portrait
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationManager.shared.allowed
    }
}
