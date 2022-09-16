//
//  DemoMapView.swift
//  GLMap
//
//  Created by Arkadi Tolkun on 15.09.22.
//  Copyright © 2022 Evgen Bodunov. All rights reserved.
//

import SwiftUI
import GLMap
import GLSearch
import GLMapSwift

struct DemoMapView: View {
    let demo: Demo
    var stylePath: String = ""
    
    let demoCases = [
        Demo.darkTheme: loadDarkTheme,
        Demo.embeddMap: showEmbedMap,
        Demo.onlineMap: showOnlineMap,
        //Demo.routing: testRouting,
        Demo.rasterOnlineMap: showRasterOnlineMap,
        Demo.zoomToBBox: zoomToBBox,
        Demo.offlineSearch: offlineSearch,
        Demo.notifications: testNotifications,
        /*Demo.singleImage: singleImageDemo,
        Demo.multiImage: multiImageDemo,*/
        Demo.markerLayer: markerLayer,
        Demo.markerLayerWithClustering: markerLayerWithClustering,
        Demo.markerLayerWithMapCSSClustering: markerLayerWithMapCSSClustering,
        Demo.multiLine: multiLineDemo,
        //Demo.track: recordGPSTrack,
        Demo.polygon: polygonDemo,
        Demo.geoJSON: geoJsonDemoPostcodes,
        /*Demo.screenshot: screenshotDemo,
        Demo.fonts: fontsDemo,
        Demo.flyTo: flyToDemo,
        Demo.downloadInBBox: downloadInBBox,
        Demo.styleReload: styleReloadDemo,*/
    ]
    
    var body: some View {
        GLMapViewUI { map in
            DispatchQueue.main.async {
                if let demo = demoCases[demo] {
                    demo(self)(map)
                }
            }
        }
    }
    
    private func loadStyle(map: GLMapView, darkTheme: Bool, carDriving: Bool) {
        guard let mainPath = GLMapManager.shared.resourcesBundle.path(forResource: "DefaultStyle", ofType: "bundle") else { return }
        let parser = GLMapStyleParser(paths: [stylePath, mainPath])

        var options = [String: String]()
        if carDriving {
            options["Style"] = "CarDriving"
        }
        if darkTheme {
            options["Theme"] = "Dark"
        }
        parser.setOptions(options, defaultValue: true)
        guard let style = parser.parseFromResources() else {
            NSLog("Can't parse style from resources")
            return
        }
        map.setStyle(style)
        map.reloadTiles()
    }
    
    private func loadDarkTheme(map: GLMapView) {
        loadStyle(map: map, darkTheme: true, carDriving: false)
    }
    
    private func showEmbedMap(map: GLMapView) {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.add(.map, path: mapPath, bbox: .empty)
            map.mapGeoCenter = GLMapGeoPoint(lat: 42.4341, lon: 19.26)
            map.mapZoomLevel = 14
        }
    }
    
    private func showOnlineMap(map: GLMapView) {
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14
    }
    
    private func showRasterOnlineMap(map: GLMapView) {
        if let osmTileSource = OSMTileSource(cachePath: "/osm.sqlite") {
            map.base = osmTileSource
        }
    }
    
    private func zoomToBBox(map: GLMapView) {
        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(lat: 52.5037, lon: 13.4102))
        bbox.add(point: GLMapPoint(lat: 53.9024, lon: 27.5618))
        
        // set center point and change zoom to make screenDistance less or equal mapView.bounds
        map.mapCenter = bbox.center
        map.mapZoom = map.mapZoom(for: bbox)
    }
    
    private func offlineSearch(map: GLMapView) {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.add(.map, path: mapPath, bbox: .empty)
            let center = GLMapGeoPoint(lat: 42.4341, lon: 19.26)
            map.mapGeoCenter = center
            map.mapZoomLevel = 14

            // Create new offline search request
            let searchOffline = GLSearch()
            // Set center of search. Objects that is near center will recive bonus while sorting happens
            searchOffline.center = GLMapPoint(lat: center.lat, lon: center.lon)
            // Set maximum number of results. By default is is 100
            searchOffline.limit = 20
            // Set locale settings. Used to boost results with locales native to user
            searchOffline.setLocaleSettings(map.localeSettings)

            let category = GLSearchCategories.shared.categoriesStarted(with: ["restaurant"], localeSettings: GLMapLocaleSettings(localesOrder: ["en"], unitSystem: .international))
            if category.count == 0 {
                return
            }

            // Logical operations between filters is AND
            // Filter results by category
            searchOffline.add(GLSearchFilter(category: category[0]))

            // Additionally search for objects with
            // word beginning "Baj" in name or alt_name,
            // "Crno" as word beginning in addr:* tags,
            // and exact "60/1" in addr:* tags.
            //
            // Expected result is restaurant Bajka at Bulevar Ivana Crnojevića 60/1 ( https://www.openstreetmap.org/node/4397752292 )
            searchOffline.add(GLSearchFilter(query: "Baj", tagSetMask: [.name, .altName]))
            searchOffline.add(GLSearchFilter(query: "Crno", tagSetMask: .address))

            let filter = GLSearchFilter(query: "60/1", tagSetMask: .address)
            // Default match type is WordStart. But we could change it to Exact or Word.
            filter.matchType = .exact
            searchOffline.add(filter)

            searchOffline.searchAsync(completionBlock: { results in
                self.displaySearchResults(map: map, results: results)
            })
        }
    }
    
    func displaySearchResults(map: GLMapView, results: GLMapVectorObjectArray) {
        let styles = GLMapMarkerStyleCollection()
        styles.addStyle(with: GLMapVectorImageFactory.shared.image(fromSvg: Bundle.main.path(forResource: "cluster", ofType: "svg")!, withScale: 0.2, andTintColor: GLMapColor(red: 0xFF, green: 0, blue: 0, alpha: 0xFF))!)

        // If marker layer constructed using array with object of any type you need to set markerLocationBlock
        styles.setMarkerLocationBlock { marker -> GLMapPoint in
            if let obj = marker as? GLMapVectorObject {
                return obj.point
            }
            return GLMapPoint()
        }

        // Data fill block used to set marker style and text
        // It could work with any user defined object type.
        // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
        styles.setMarkerDataFill { _, data in
            data.setStyle(0)
        }

        let layer = GLMapMarkerLayer(markers: results.array(), andStyles: styles, clusteringRadius: 0, drawOrder: 2)
        map.add(layer)

        if results.count != 0 {
            let bbox = results.bbox
            map.mapCenter = bbox.center
            map.mapZoom = map.mapZoom(for: bbox)
        }
    }
    
    func testNotifications(map: GLMapView) {
        // called every frame
        map.bboxChangedBlock = { (bbox: GLMapBBox) in
            print("bboxChanged \(bbox)")
        }

        // called only after movement
        map.mapDidMoveBlock = { (bbox: GLMapBBox) in
            print("mapDidMove \(bbox)")
        }
    }
    
    func markerLayer(map: GLMapView) {
        // Create marker image
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg") {
            if let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: 0.2) {
                // Create style collection - it's storage for all images possible to use for markers
                let style = GLMapMarkerStyleCollection()
                style.addStyle(with: image)

                // If marker layer constructed using GLMapVectorObjectArray location of marker is automatically calculated as
                // [GLMapVectorObject point]. So you don't need to set markerLocationBlock.
                // style.setMarkerLocationBlock()

                // Data fill block used to set marker style and text
                // It could work with any user defined object type.
                // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
                style.setMarkerDataFill { _, data in
                    data.setStyle(0)
                }

                // Load UK postal codes from GeoJSON
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json") {
                    if let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        // Put our array of objects into marker layer. It could be any custom array of objects.
                        // Disable clustering in this demo
                        let markerLayer = GLMapMarkerLayer(vectorObjects: objects, andStyles: style, clusteringRadius: 0, drawOrder: 2)
                        // Add marker layer on map
                        map.add(markerLayer)
                        let bbox = objects.bbox
                        map.mapCenter = bbox.center
                        map.mapZoom = map.mapZoom(for: bbox)
                    }
                }
            }
        }
    }
    
    func markerLayerWithClustering(map: GLMapView) {
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg") {
            // We use different colours for our clusters
            let tintColors = [
                GLMapColor(red: 33, green: 0, blue: 255, alpha: 255),
                GLMapColor(red: 68, green: 195, blue: 255, alpha: 255),
                GLMapColor(red: 63, green: 237, blue: 198, alpha: 255),
                GLMapColor(red: 15, green: 228, blue: 36, alpha: 255),
                GLMapColor(red: 168, green: 238, blue: 25, alpha: 255),
                GLMapColor(red: 214, green: 234, blue: 25, alpha: 255),
                GLMapColor(red: 223, green: 180, blue: 19, alpha: 255),
                GLMapColor(red: 255, green: 0, blue: 0, alpha: 255),
            ]

            // Create style collection - it's storage for all images possible to use for markers and clusters
            let styleCollection = GLMapMarkerStyleCollection()

            // Render possible images from svgpb
            var maxWidth = 0.0
            for i in 0 ..< tintColors.count {
                let scale = 0.2 + 0.1 * Double(i)
                if let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: scale, andTintColor: tintColors[i]) {
                    if maxWidth < Double(image.size.width) {
                        maxWidth = Double(image.size.width)
                    }
                    styleCollection.addStyle(with: image)
                }
            }

            // Create style for text
            let textStyle = GLMapVectorStyle.createStyle("{text-color:black;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}")

            // If marker layer constructed using GLMapVectorObjectArray location of marker is automatically calculated as
            // [GLMapVectorObject point]. So you don't need to set markerLocationBlock.
            // styleCollection.setMarkerLocationBlock()

            // Data fill block used to set marker style and text
            // It could work with any user defined object type.
            // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
            styleCollection.setMarkerDataFill { marker, data in
                if let obj = marker as? GLMapVectorObject {
                    data.setStyle(0)
                    if let nameValue = obj.value(forKey: "name") {
                        if let name = nameValue.asString() {
                            data.setText(name, offset: CGPoint(x: 0, y: 8), style: textStyle!)
                        }
                    }
                }
            }

            // Union fill block used to set style for cluster object. First param is number objects inside the cluster and second is marker object.
            styleCollection.setMarkerUnionFill { markerCount, data in
                // we have 8 marker styles for 1, 2, 4, 8, 16, 32, 64, 128+ markers inside
                var markerStyle = Int(log2(Double(markerCount)))
                if markerStyle >= tintColors.count {
                    markerStyle = tintColors.count - 1
                }
                data.setStyle(UInt(markerStyle))
                data.setText("\(markerCount)", offset: CGPoint.zero, style: textStyle!)
            }

            // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on main thread only when data is loaded.
            DispatchQueue.global().async {
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json") {
                    if let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        let markerLayer = GLMapMarkerLayer(vectorObjects: objects, andStyles: styleCollection, clusteringRadius: maxWidth / 2, drawOrder: 2)
                        let bbox = objects.bbox

                        DispatchQueue.main.async {
                            map.add(markerLayer)
                            map.mapCenter = bbox.center
                            map.mapZoom = map.mapZoom(for: bbox)
                        }
                    }
                }
            }
        }
    }

    func markerLayerWithMapCSSClustering(map: GLMapView) {
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg") {
            // We use different colours for our clusters
            let tintColors = [
                GLMapColor(red: 33, green: 0, blue: 255, alpha: 255),
                GLMapColor(red: 68, green: 195, blue: 255, alpha: 255),
                GLMapColor(red: 63, green: 237, blue: 198, alpha: 255),
                GLMapColor(red: 15, green: 228, blue: 36, alpha: 255),
                GLMapColor(red: 168, green: 238, blue: 25, alpha: 255),
                GLMapColor(red: 214, green: 234, blue: 25, alpha: 255),
                GLMapColor(red: 223, green: 180, blue: 19, alpha: 255),
                GLMapColor(red: 255, green: 0, blue: 0, alpha: 255),
            ]

            // Create style collection - it's storage for all images possible to use for markers and clusters
            let styleCollection = GLMapMarkerStyleCollection()

            // Render possible images from svgpb
            var maxWidth = 0.0
            for i in 0 ..< tintColors.count {
                let scale = 0.2 + 0.1 * Double(i)
                if let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: scale, andTintColor: tintColors[i]) {
                    if maxWidth < Double(image.size.width) {
                        maxWidth = Double(image.size.width)
                    }
                    let styleIndex = styleCollection.addStyle(with: image)
                    styleCollection.setStyleName("uni\(styleIndex)", forStyleIndex: styleIndex)
                }
            }

            // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on main thread only when data is loaded.
            DispatchQueue.global().async {
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json") {
                    if let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        if let cascadeStyle = GLMapVectorCascadeStyle.createStyle("""
                        node {
                            icon-image:"uni0";
                            text-priority: 100;
                            text:eval(tag("name"));
                            text-color:#2E2D2B;
                            font-size:12;
                            font-stroke-width:1pt;
                            font-stroke-color:#FFFFFFEE;
                        }
                        node[count>=2]{
                            icon-image:"uni1";
                            text-priority: 101;
                            text:eval(tag("count"));
                        }
                        node[count>=4]{
                            icon-image:"uni2";
                            text-priority: 102;
                        }
                        node[count>=8]{
                            icon-image:"uni3";
                            text-priority: 103;
                        }
                        node[count>=16]{
                            icon-image:"uni4";
                            text-priority: 104;
                        }
                        node[count>=32]{
                            icon-image:"uni5";
                            text-priority: 105;
                        }
                        node[count>=64]{
                            icon-image:"uni6";
                            text-priority: 106;
                        }
                        node[count>=128]{
                            icon-image:"uni7";
                            text-priority: 107;
                        }
                        """) {
                            let markerLayer = GLMapMarkerLayer(vectorObjects: objects, cascadeStyle: cascadeStyle, styleCollection: styleCollection, clusteringRadius: maxWidth / 2, drawOrder: 2)
                            let bbox = objects.bbox
                            DispatchQueue.main.async {
                                map.add(markerLayer)
                                map.mapCenter = bbox.center
                                map.mapZoom = map.mapZoom(for: bbox)
                            }
                        }
                    }
                }
            }
        }
    }

    func multiLineDemo(map: GLMapView) {
        let multiline = [
            GLMapPointArray([
                GLMapPoint(lat: 53.8869, lon: 27.7151), // Minsk
                GLMapPoint(lat: 50.4339, lon: 30.5186), // Kiev
                GLMapPoint(lat: 52.2251, lon: 21.0103), // Warsaw
                GLMapPoint(lat: 52.5037, lon: 13.4102), // Berlin
                GLMapPoint(lat: 48.8505, lon: 2.3343), // Paris
            ]),
            GLMapPointArray([
                GLMapPoint(lat: 52.3690, lon: 4.9021), // Amsterdam
                GLMapPoint(lat: 50.8263, lon: 4.3458), // Brussel
                GLMapPoint(lat: 49.6072, lon: 6.1296), // Luxembourg
            ]),
        ]
        if let style = GLMapVectorCascadeStyle.createStyle("line{width: 2pt; color:green;}") {
            let drawable = GLMapVectorLayer()
            drawable.setVectorObject(GLMapVectorObject(multiline: multiline), with: style, completion: nil)
            map.add(drawable)
        }
    }

    func polygonDemo(map: GLMapView) {
        let pointCount = 25
        let centerPoint = GLMapGeoPoint(lat: 53, lon: 27)
        let radiusOuter = 10.0
        let radiusInner = 5.0
        let sectorSize = 2 * Double.pi / Double(pointCount)

        let outerRing = GLMapPointArray(count: UInt(pointCount)) { i -> GLMapPoint in
            GLMapPoint(lat: centerPoint.lat + cos(sectorSize * Double(i)) * radiusOuter,
                       lon: centerPoint.lon + sin(sectorSize * Double(i)) * radiusOuter)
        }

        let innerRing = GLMapPointArray(count: UInt(pointCount)) { i -> GLMapPoint in
            GLMapPoint(lat: centerPoint.lat + cos(sectorSize * Double(i)) * radiusInner,
                       lon: centerPoint.lon + sin(sectorSize * Double(i)) * radiusInner)
        }

        if let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#10106050; width:4pt; color:green;}") {
            let drawable = GLMapVectorLayer()
            drawable.setVectorObject(GLMapVectorObject(polygonOuterRings: [outerRing], innerRings: [innerRing]), with: style, completion: nil)
            map.add(drawable)
        }
        map.mapGeoCenter = centerPoint
    }

    func geoJsonDemoPostcodes(map: GLMapView) {
        guard let path = Bundle.main.path(forResource: "uk_postcodes", ofType: "geojson") else {
            return
        }

        do {
            let geojson = try String(contentsOfFile: path)

            guard let objects = try? GLMapVectorObject.createVectorObjects(fromGeoJSON: geojson) else {
                return
            }
            guard let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:green; width:1pt; color:red;}") else {
                return
            }

            let drawable = GLMapVectorLayer()
            drawable.setVectorObjects(objects, with: style, completion: nil)
            map.add(drawable)

            let bbox = objects.bbox
            map.mapCenter = bbox.center
            map.mapZoom = map.mapZoom(for: bbox)
        } catch {
            return
        }
    }

    func geoJsonDemo(map: GLMapView) {
        guard let objects = try? GLMapVectorObject.createVectorObjects(fromGeoJSON: """
        [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [30.5186, 50.4339]}, "properties": {"id": "1", "text": "test1"}},
        {"type": "Feature", "geometry": {"type": "Point", "coordinates": [27.7151, 53.8869]}, "properties": {"id": "2", "text": "test2"}},
        {"type":"LineString", "coordinates": [ [27.7151, 53.8869], [30.5186, 50.4339], [21.0103, 52.2251], [13.4102, 52.5037], [2.3343, 48.8505]]},
        {"type":"Polygon", "coordinates":[[ [0.0, 10.0], [10.0, 10.0], [10.0, 20.0], [0.0, 20.0] ],[ [2.0, 12.0], [ 8.0, 12.0], [ 8.0, 18.0], [2.0, 18.0] ]]}]
        """),
            let style = GLMapVectorCascadeStyle.createStyle("""
            node[id=1] {
                icon-image:"bus.svg";
                icon-scale:0.5;
                icon-tint:green;
                text:eval(tag('text'));
                text-color:red;
                font-size:12;
                // add priority to this text over map objects
                text-priority: 20;
            }
            node|z-9[id=2] {
                icon-image:"bus.svg";
                icon-scale:0.7;
                icon-tint:blue;
                text:eval(tag('text'));
                text-color:red;
                font-size:12;
                // add priority to this text over map objects
                text-priority: 20;
            }
            line {
                linecap: round;
                width: 5pt;
                color:blue;
            }
            area {
                fill-color:green;
                width:1pt;
                color:red;
            }
            """) else { return }
        // When GLMapDrawable created without drawOrder:param it's displayed with map objects, and could hide other objects.
        // When drawOrder is set, then drawable interact with other objects with same drawOrder value.
        var drawable = GLMapVectorLayer()
        drawable.setVectorObject(objects[0], with: style, completion: nil)
        map.add(drawable)
        objects.removeObject(at: 0)

        drawable = GLMapVectorLayer()
        drawable.setVectorObjects(objects, with: style, completion: nil)
        map.add(drawable)
    }

}
