//
//  AppDelegate.swift
//  SwiftDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import GLMap
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // FIXME: set apikey from https://user.getyourmap.com/apps
        GLMapManager.shared.apiKey = UserDefaults.standard.string(forKey: "apiKey")
        return true
    }
}
