//
//  SiriAIDemoApp.swift
//  SiriAIDemo
//
//  Created by Itsuki on 2026/11/04.
//

import AppIntents
import SwiftUI

@main
struct SiriAIDemoApp: App {
    private let manager: GroceryManager
    init() {
        let manager = GroceryManager()
        self.manager = manager
        AppDependencyManager.shared.add(dependency: manager)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(manager)
        }
    }
}
