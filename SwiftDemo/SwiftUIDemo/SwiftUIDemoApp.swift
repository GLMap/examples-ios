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
        guard GLMapManager.activate(apiKey: "YOUR_API_KEY") else {
            fatalError("GLMap SDK initialization failed")
        }
        GLMapManager.shared.tileDownloadingAllowed = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
