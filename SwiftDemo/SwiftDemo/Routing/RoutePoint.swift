//
//  RoutePoint.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLRoute

class RoutePoint : Equatable {
    let pt: GLRoutePoint
    let isCurrentLocation: Bool

    var location: GLMapGeoPoint { return pt.pt }
    var index: Int { return Int(pt.originalIndex) }

    lazy var name = {
        return "Point \(index)"
    }()

    init(pt: GLRoutePoint, isCurrentLocation: Bool) {
        self.pt = pt
        self.isCurrentLocation = isCurrentLocation
    }

    init(pt: GLMapGeoPoint, index: Int, isCurrentLocation: Bool) {
        self.pt = GLRoutePoint(pt: pt, heading: Double.nan, originalIndex: Int32(index), isStop: true, allowUTurn: false)
        self.isCurrentLocation = isCurrentLocation
    }

    static func == (lhs: RoutePoint, rhs: RoutePoint) -> Bool {
        return lhs === rhs
    }
}
