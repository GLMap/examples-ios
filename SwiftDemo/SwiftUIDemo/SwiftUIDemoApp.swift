//
//  SwiftUIDemoApp.swift
//  SwiftUIDemo
//
//  Created by Evgen Bodunov on 25.04.23.
//  Copyright © 2023 Evgen Bodunov. All rights reserved.
//

import GLMap
import SwiftUI

@main
struct SwiftUIDemoApp: App {
    init() {
        GLMapManager.activate(apiKey: <#API key#>)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
