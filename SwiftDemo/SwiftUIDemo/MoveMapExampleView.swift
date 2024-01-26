//
//  MoveMapExampleView.swift
//  SwiftUIDemo
//
//  Created by Evgen Bodunov on 26.04.23.
//  Copyright © 2023 Evgen Bodunov. All rights reserved.
//

import CoreLocation
import GLMap
import GLMapSwift
import SwiftUI

struct MoveMapExampleView: View {
    @State private var zoomLevel: Double = 3
    @State private var mapCenter: GLMapGeoPoint = .init(lat: 53, lon: 27)

    var body: some View {
        GLMapViewRepresentable(geoCenter: $mapCenter, zoomLevel: $zoomLevel) { point in
            print("Tap at: ", point.lat, point.lon)

            // Europe
            let newLatitude = Double.random(in: 35 ... 70)
            let newLongitude = Double.random(in: -10 ... 40)
            mapCenter = GLMapGeoPoint(lat: newLatitude, lon: newLongitude)
            zoomLevel = Double.random(in: 3 ..< 9)
        }
    }
}

struct DisplayMarkersExampleView: View {
    var body: some View {
        GLMapViewRepresentable(onTap: { coordinate in
            print("Tapped at point: \(coordinate)")
        })
    }
}
