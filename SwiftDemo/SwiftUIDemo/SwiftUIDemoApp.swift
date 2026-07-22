//
//  SwiftUIDemoApp.swift
//  SwiftUIDemo
//
//  Created by Evgen Bodunov on 25.04.23.
//  Copyright © 2023 Evgen Bodunov. All rights reserved.
//

import GLMap
import GLMapSwift
import SwiftUI

@main
struct SwiftUIDemoApp: App {
    init() {
        // Insert your API key from https://user.globus.software/apps/
        GLMapManager.activate(apiKey: "39f30206-5eee-4db4-919d-31f86f6ce723")
        GLMapManager.shared.tileDownloadingAllowed = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
