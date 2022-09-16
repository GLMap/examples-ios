//
//  ContentView.swift
//  MacOS
//
//  Created by Arkadiy Tolkun on 2.02.21.
//  Copyright © 2021 Evgen Bodunov. All rights reserved.
//

import SwiftUI

enum Demo {
    case offlineMap
    case darkTheme
    case embeddMap
    case onlineMap
    //case routing
    //case routeTracker
    case rasterOnlineMap
    case zoomToBBox
    case offlineSearch
    case notifications
    //case singleImage
    //case multiImage
    case markerLayer
    case markerLayerWithClustering
    case markerLayerWithMapCSSClustering
    //case track
    case multiLine
    case polygon
    case geoJSON
    //case screenshot
    //case fonts
    //case flyTo
    //case downloadInBBox
    //case styleReload
    //case downloadMap
}

struct TableRow: Identifiable {
    let id: Demo
    let name: String
    let description: String
    init(_ id: Demo, name: String, description: String = "") {
        self.id = id
        self.name = name
        self.description = description
    }
}
struct ContentView: View {
    let tableRows = [
        TableRow(.offlineMap, name: "Open offline map"),
        TableRow(.darkTheme, name: "Dark theme"),
        TableRow(.embeddMap, name: "Open embedd map"),
        TableRow(.onlineMap, name: "Open online map", description: "Downloads tiles one by one"),
        //TableRow(.routing, name: "Routing", description: "Offline routing requires downloaded navigation data"),
        //TableRow(.routeTracker, name: "Route Tracker", description: "Tracking user while it moves along the route"),
        TableRow(.rasterOnlineMap, name: "Raster online map", description: "Downloads raster tiles one by one from custom tile source"),

        TableRow(.zoomToBBox, name: "Zoom to bbox"),
        TableRow(.offlineSearch, name: "Offline search"),
        TableRow(.notifications, name: "Notification test"),
        //TableRow(.singleImage, name: "GLMapDrawable demo", description: "For one pin or any other image"),
        //TableRow(.multiImage, name: "GLMapImageGroup demo", description: "For large set of pins with smaller set of images"),

        TableRow(.markerLayer, name: "GLMapMarkerLayer demo"),
        TableRow(.markerLayerWithClustering, name: "GLMapMarkerLayer with clustering"),
        TableRow(.markerLayerWithMapCSSClustering, name: "GLMapMarkerLayer with MapCSS clustering"),

        //TableRow(.track, name: "GPS track recording"),
        TableRow(.multiLine, name: "Add multiline"),

        TableRow(.polygon, name: "Add polygon"),
        TableRow(.geoJSON, name: "Load GeoJSON"),
        //TableRow(.screenshot, name: "Take screenshot"),
        //TableRow(.fonts, name: "Fonts"),
        //TableRow(.flyTo, name: "Fly to"),

        //TableRow(.downloadInBBox, name: "Download data in bounding box"),
        //TableRow(.styleReload, name: "Style live reload"),

        //TableRow(.downloadMap, name: "Download offline map"),
    ]
    @State private var selectedRow = Demo.offlineMap
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tableRows, id: \.id) { row in
                    NavigationLink(row.name, destination: DemoMapView(demo: row.id))
                }
            }.frame(minWidth: 320).navigationTitle("Demos")
        }
    }
}
