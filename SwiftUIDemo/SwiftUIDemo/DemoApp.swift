//
//  MacOSApp.swift
//  MacOS
//
//  Created by Arkadiy Tolkun on 2.02.21.
//  Copyright © 2021 Evgen Bodunov. All rights reserved.
//

import GLMap
import SwiftUI

@main
struct DemoApp: App {
    init() {
        // Insert your API key from https://user.getyourmap.com/apps
        GLMapManager.activate(apiKey: <#API key#>)
    }

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            // use min width & height to make the start screen 800 & 1000 and make max width & height to infinity to make screen expandable when user stretch the screen
            ContentView().frame(minWidth: 640, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity, alignment: .center)
            #else
            ContentView()
            #endif
        }
    }
}
