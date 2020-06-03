//
//  Route.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLRoute

class Route {
    let route: GLRoute
    let params: RouteParams

    init(route: GLRoute, params: RouteParams) {
        self.route = route
        self.params = params
    }
}
