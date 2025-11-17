//
//  URFocusApp.swift
//  URFocus
//
//  Created by Lior Zendel on 10/17/25.
//

import SwiftUI
import FirebaseCore

@main
struct URFocusApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
