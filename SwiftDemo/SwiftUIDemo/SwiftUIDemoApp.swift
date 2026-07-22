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
        GLMapManager.activate(apiKey: <#API key#>)
        GLMapManager.shared.tileDownloadingAllowed = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
