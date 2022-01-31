//
//  AppDelegate.swift
//  SwiftDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import GLMapSwift
import GLMap
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Insert your API key from https://user.getyourmap.com/apps
        GLMapManager.activate(apiKey: <#API key#>)

        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = .systemFill
            appearance.configureWithOpaqueBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        return true
    }
}
