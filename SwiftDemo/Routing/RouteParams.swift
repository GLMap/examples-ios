//
//  RouteParams.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLMap
import GLRoute

class RouteParams: Equatable {
    let points: [RoutePoint]
    let mode: GLRouteMode

    var startPoint: RoutePoint { return points.first! }
    var finishPoint: RoutePoint { return points.last! }

    var haveCurrentLocation: Bool { return points.firstIndex(where: { $0.isCurrentLocation }) != nil }

    static func == (lhs: RouteParams, rhs: RouteParams) -> Bool {
        return lhs.mode == rhs.mode && lhs.points == rhs.points
    }

    init(points: [RoutePoint], mode: GLRouteMode) {
        assert(points.count >= 2)
        self.points = points
        self.mode = mode
    }

    func changing(mode: GLRouteMode) -> RouteParams {
        return RouteParams(points: points, mode: mode)
    }

    func changing(_ point: RoutePoint, to: RoutePoint) -> RouteParams {
        let newPoints = points.map { $0 === point ? to : $0 }
        return RouteParams(points: newPoints, mode: mode)
    }

    func adding(_ point: RoutePoint) -> RouteParams {
        var newPoints = points
        newPoints.append(point)
        return RouteParams(points: points, mode: mode)
    }

    func deleting(_ point: RoutePoint) -> RouteParams {
        var newPoints = self.points
        if let index = points.firstIndex(of: point) {
            newPoints.remove(at: index)
        }
        return RouteParams(points: newPoints, mode: mode)
    }

    func findRoutePoint(_ point: GLMapPoint, mapView: GLMapView, maxDistance: CGFloat) -> RoutePoint? {
        let tmp = mapView.makeMapPoint(fromDisplayDelta: CGPoint(x: maxDistance, y: 0))
        let maxDist = hypot(tmp.x, tmp.y)
        for pt in points where !pt.isCurrentLocation {
            let position = GLMapPoint(geoPoint: pt.location)
            let dist = hypot(point.x - position.x, point.y - position.y)
            if dist < maxDist {
                return pt
            }
        }
        return nil
    }
}
