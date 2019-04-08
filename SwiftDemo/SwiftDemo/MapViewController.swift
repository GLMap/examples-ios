//
//  MapViewController.swift
//  SwiftDemo
//
//  Created by Evgen Bodunov on 11/16/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import GLMap
import GLMapSwift
import GLRoute
import GLSearch
import UIKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    let map = GLMapView()
    let downloadButton = UIButton(type: .system)
    let locationManager = CLLocationManager()

    var trackData: GLMapTrackData?
    var track: GLMapTrack?

    typealias Demo = ViewController.Demo

    var currentDemo: Demo = .OfflineMap

    let demoCases = [
        Demo.OfflineMap: showOfflineMap,
        Demo.EmbeddMap: showEmbedMap,
        Demo.OnlineMap: showOnlineMap,
        Demo.Routing: testRouting,
        Demo.RasterOnlineMap: showRasterOnlineMap,
        Demo.ZoomToBBox: zoomToBBox,
        Demo.OfflineSearch: offlineSearch,
        Demo.Notifications: testNotifications,
        Demo.SingleImage: singleImageDemo,
        Demo.MultiImage: multiImageDemo,
        Demo.MarkerLayer: markerLayer,
        Demo.MarkerLayerWithClustering: markerLayerWithClustering,
        Demo.MarkerLayerWithMapCSSClustering: markerLayerWithMapCSSClustering,
        Demo.MultiLine: multiLineDemo,
        Demo.Track: recordGPSTrack,
        Demo.Polygon: polygonDemo,
        Demo.GeoJSON: geoJsonDemoPostcodes,
        Demo.Screenshot: screenshotDemo,
        Demo.Fonts: fontsDemo,
        Demo.FlyTo: flyToDemo,
        Demo.TilesBulkDownload: tilesBulkDownload,
        Demo.StyleReload: styleReloadDemo,
    ]

    var tilesToDownload: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        title = "Demo map"

        map.frame = view.bounds
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation() // don't forget to stop updating location
        locationManager.delegate = map

        map.showUserLocation = true

        view.addSubview(map)

        downloadButton.setTitle("Download Map", for: .normal)
        downloadButton.addTarget(self, action: #selector(MapViewController.downloadButtonTap), for: .touchUpInside)
        view.addSubview(downloadButton)

        downloadButton.center = view.center

        updateDownloadButton()

        map.centerTileStateChangedBlock = { [weak self] in
            self?.updateDownloadButton()
        }

        map.mapDidMoveBlock = { [weak self] (_: GLMapBBox) in
            self?.updateDownloadButtonText()
        }

        NotificationCenter.default.addObserver(forName: GLMapDownloadTask.downloadProgress, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateDownloadButtonText()
        }

        NotificationCenter.default.addObserver(forName: GLMapDownloadTask.downloadFinished, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.map.reloadTiles()
            self?.updateDownloadButton()
        }

        if let demo = demoCases[currentDemo] {
            demo(self)()
        } else {
            print("Missing demo for \(currentDemo)")
        }
    }

    override func viewWillDisappear(_: Bool) {
        // restore state before next demo
        GLMapManager.shared.tileDownloadingAllowed = false

        map.longPressGestureBlock = nil
        map.tapGestureBlock = nil

        if mapImageGroup != nil {
            map.remove(mapImageGroup!)
            mapImageGroup = nil
        }
    }

    func updateDownloadButton() {
        switch map.centerTileState {
        case .hasData:
            if downloadButton.isHidden == false {
                downloadButton.isHidden = true
            }
        case .noData:
            if downloadButton.isHidden {
                downloadButton.isHidden = false
            }
            break
        default:
            break
        }
    }

    var mapToDownload: GLMapInfo?

    func updateDownloadButtonText() {
        if map.centerTileState == .noData {
            let mapCenter = map.mapCenter

            mapToDownload = GLMapManager.shared.map(at: mapCenter)

            if let map = mapToDownload {
                if map.state(for: .map) == .downloaded || map.distance(fromBorder: mapCenter) > 0.0 {
                    mapToDownload = nil
                }
            }

            if let map = mapToDownload {
                let title: String
                if let task = GLMapManager.shared.downloadTask(forMap: map) {
                    let progress = task.downloaded * 100 / task.total
                    title = String(format: "Downloading %@ %d%%", map.name(), progress)
                } else {
                    title = "Download \(map.name())"
                }

                downloadButton.setTitle(title, for: .normal)
            } else {
                downloadButton.setTitle("Download Maps", for: .normal)
            }
        }
    }

    @objc func downloadButtonTap() {
        if let map = mapToDownload {
            let downloadTask = GLMapManager.shared.downloadTask(forMap: map)
            if let task = downloadTask {
                task.cancel()
            } else {
                GLMapManager.shared.downloadDataSets(.all, forMap: map, withCompletionBlock: nil)
            }
        } else {
            performSegue(withIdentifier: "DownloadMaps", sender: self)
        }
    }

    // MARK: Demo functions

    func showOfflineMap() {
        // nonthing to do
    }

    func showEmbedMap() {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.addMap(mapPath)
            map.mapGeoCenter = GLMapGeoPoint(lat: 42.4341, lon: 19.26)
            map.mapZoomLevel = 14
        }
    }

    var routingMode: UISegmentedControl?
    var networkMode: UISegmentedControl?
    var startPoint = GLMapGeoPointMake(53.844720, 27.482352)
    var endPoint = GLMapGeoPointMake(53.931935, 27.583995)
    var menuPoint: GLMapGeoPoint?
    var routeTrack: GLMapTrack?
    var valhallaConfig: String?

    func testRouting() {
        // we'll look for in resources default style path first, then in app bundle. After that we could load our images in GLMapVectorStyle, e.g. track-arrows.svgpb
        guard let stylePath = Bundle.main.path(forResource: "DefaultStyle", ofType: "bundle") else {
            NSLog("Can't find DefaultStyle.bundle in resources")
            return
        }
        map.loadStyle(fromPaths: [stylePath, Bundle.main.bundlePath])
        
        guard let valhallaConfigPath = Bundle.main.path(forResource: "valhalla", ofType: "json") else {
            NSLog("Can't find valhalla.json in resources")
            return
        }
        
        do {
            valhallaConfig = try String.init(contentsOfFile: valhallaConfigPath)
        } catch {
            NSLog("Can't read contents of valhalla.json")
            return
        }
        
        routingMode = UISegmentedControl(items: ["Auto", "Bike", "Walk"])
        routingMode?.selectedSegmentIndex = 0
        routingMode?.addTarget(self, action: #selector(MapViewController.updateRoute), for: .valueChanged)

        networkMode = UISegmentedControl(items: ["Online", "Offline"])
        networkMode?.selectedSegmentIndex = 0
        networkMode?.addTarget(self, action: #selector(MapViewController.updateRoute), for: .valueChanged)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: routingMode!),
            UIBarButtonItem(customView: networkMode!),
        ]
        navigationItem.prompt = "Tap on map to select departure and destination points"

        var bbox = GLMapBBox.empty
        bbox.addPoint(GLMapPointFromMapGeoPoint(startPoint))
        bbox.addPoint(GLMapPointFromMapGeoPoint(endPoint))
        map.mapCenter = bbox.center
        map.mapZoom = map.mapZoom(for: bbox) / 2

        map.tapGestureBlock = { [weak self] pt in
            if let sself = self {
                let menu = UIMenuController.shared
                if !menu.isMenuVisible {
                    sself.menuPoint = GLMapGeoPointFromMapPoint(sself.map.makeMapPoint(fromDisplay: pt))
                    sself.becomeFirstResponder()
                    menu.setTargetRect(CGRect(x: pt.x, y: pt.y, width: 1, height: 1), in: sself.map)
                    menu.menuItems = [
                        UIMenuItem(title: "Departure", action: #selector(MapViewController.setDeparture)),
                        UIMenuItem(title: "Destination", action: #selector(MapViewController.setDestination)),
                    ]
                    menu.setMenuVisible(true, animated: true)
                }
            }
        }
        updateRoute()
    }

    @objc func setDeparture() {
        startPoint = menuPoint!
        updateRoute()
    }

    @objc func setDestination() {
        endPoint = menuPoint!
        updateRoute()
    }

    @objc func updateRoute() {
        let pts = [
            GLRoutePoint(pt: startPoint, heading: Double.nan, isStop: true),
            GLRoutePoint(pt: endPoint, heading: Double.nan, isStop: true),
        ]

        var mode = GLMapRouteMode.walk
        if routingMode?.selectedSegmentIndex == 0 {
            mode = GLMapRouteMode.drive
        } else if routingMode?.selectedSegmentIndex == 1 {
            mode = GLMapRouteMode.cycle
        }

        let completion = { (result: GLRoute?, error: Error?) in
            if let routeData = result {
                if let trackData = routeData.trackData(with: GLMapColor(red: 50, green: 200, blue: 0, alpha: 200)) {
                    if let track = self.routeTrack {
                        track.setTrackData(trackData)
                    } else {
                        let track = GLMapTrack(drawOrder: 5, andTrackData: trackData)
                        track.setStyle(GLMapVectorStyle.createStyle("{width: 7pt; fill-image:\"track-arrow.svgpb\";}"))
                        self.map.add(track)
                        self.routeTrack = track
                    }
                }
            }
            if let error = error {
                self.displayAlert("Routing error", message: error.localizedDescription)
            }
        }

        if networkMode?.selectedSegmentIndex == 0 {
            GLRoute.request(withPoints: pts, count: 2, mode: mode, locale: "en", units: .international, completionBlock: completion)
        } else {
            GLRoute.offlineRequest(withConfig: valhallaConfig!, points: pts, count: 2, mode: mode, locale: "en", units: .international, completionBlock: completion)
        }
    }

    func showOnlineMap() {
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14
    }

    func showRasterOnlineMap() {
        if let osmTileSource = OSMTileSource(cachePath: "/osm.sqlite") {
            map.rasterTileSources = [osmTileSource]
        }
    }

    func zoomToBBox() {
        // get pixel coordinates of geo points
        var bbox = GLMapBBox.empty

        bbox.addPoint(GLMapPoint(lat: 52.5037, lon: 13.4102))
        bbox.addPoint(GLMapPoint(lat: 53.9024, lon: 27.5618))

        // set center point and change zoom to make screenDistance less or equal mapView.bounds
        map.mapCenter = bbox.center
        map.mapZoom = map.mapZoom(for: bbox)
    }

    func offlineSearch() {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.addMap(mapPath)
            let center = GLMapGeoPoint(lat: 42.4341, lon: 19.26)
            map.mapGeoCenter = center
            map.mapZoomLevel = 14

            // Create new offline search request
            let searchOffline = GLSearch()
            // Set center of search. Objects that is near center will recive bonus while sorting happens
            searchOffline.center = GLMapPointMakeFromGeoCoordinates(center.lat, center.lon)
            // Set maximum number of results. By default is is 100
            searchOffline.limit = 20
            // Set locale settings. Used to boost results with locales native to user
            searchOffline.setLocaleSettings(map.localeSettings)

            let category = GLSearchCategories.shared.categoriesStarted(with: ["restaurant"], localeSettings: GLMapLocaleSettings.init(localesOrder: ["en"]))
            if category.count == 0 {
                return
            }
            
            // Logical operations between filters is AND
            // Filter results by category
            searchOffline.add(GLSearchFilter(category: category[0]))
            
            // Additionally search for objects with
            // word beginning "Baj" in name or alt_name,
            // "Crno" as word beginning in name, alt_name or andd:* tags,
            // and exact "60/1" in name, alt_name or addr:* tags.
            //
            // Logical operation between words in filter is OR, so we have to create one filter per word.
            //
            // Expected result is restaurant Bajka at Bulevar Ivana Crnojevića 60/1 ( https://www.openstreetmap.org/node/4397752292 )
            searchOffline.add(GLSearchFilter(name: "Baj", localeSettings: map.localeSettings, useGeoCodeNames: false))
            searchOffline.add(GLSearchFilter(name: "Crno", localeSettings: map.localeSettings, useGeoCodeNames: true))
            
            let filter = GLSearchFilter(name: "60/1", localeSettings: map.localeSettings, useGeoCodeNames: true)
            // Default match type is WordStart. But we could change it to Exact or Word.
            filter.matchType = .exact
            searchOffline.add(filter)

            searchOffline.start(completionBlock: { results in
                DispatchQueue.main.async {
                    self.displaySearchResults(results: results)
                }
            })
        }
    }

    func displaySearchResults(results: [GLMapVectorObject]) {
        let styles = GLMapMarkerStyleCollection()
        styles.addStyle(with: GLMapVectorImageFactory.shared.image(fromSvgpb: Bundle.main.path(forResource: "cluster", ofType: "svgpb")!, withScale: 0.2, andTintColor: GLMapColor(red: 0xFF, green: 0, blue: 0, alpha: 0xFF))!)

        // If marker layer constructed using array with object of any type you need to set markerLocationBlock
        styles.setMarkerLocationBlock { (marker) -> GLMapPoint in
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

        let layer = GLMapMarkerLayer(markers: results, andStyles: styles, clusteringRadius: 0, drawOrder: 2)
        map.add(layer)

        if results.count != 0 {
            var bbox = GLMapBBox.empty
            for object in results {
                bbox.addPoint(object.point)
            }
            map.mapCenter = bbox.center
            map.mapZoom = map.mapZoom(for: bbox)
        }
    }

    func testNotifications() {
        // called every frame
        map.bboxChangedBlock = { (bbox: GLMapBBox) in
            print("bboxChanged \(bbox)")
        }

        // called only after movement
        map.mapDidMoveBlock = { (bbox: GLMapBBox) in
            print("mapDidMove \(bbox)")
        }
    }

    var mapDrawable: GLMapDrawable = GLMapDrawable(drawOrder: 3)

    func singleImageDemo() {
        if let image = UIImage(named: "pin1.png", in: nil, compatibleWith: nil) {
            mapDrawable.setImage(image, for: map, completion: nil)
            mapDrawable.hidden = true
            map.add(mapDrawable)
        }

        // we'll just add button for this demo
        let barButton = UIBarButtonItem(title: "Add image", style: .plain, target: self, action: #selector(MapViewController.addImageButtonTap))
        navigationItem.rightBarButtonItem = barButton
        addImageButtonTap(barButton);
        
        drawableImage()
        drawableImageWithDrawOrder()
    }

    func drawableImage() {
        // original tile url is https://tile.openstreetmap.org/3/4/2.png
        // we'll show how to calculate it's position on map in GLMapPoints
        let tilePosZ:Int32 = 3, tilePosX:Int32 = 4, tilePosY:Int32 = 2
        
        // world size divided to number of tiles at this zoom level
        let tilesForZoom : Int32 = 1 << tilePosZ
        let tileSize = GLMapPointMax / tilesForZoom;
        
        // Drawables created using default constructor is added on map as polygon with layer:0; and z-index:0;
        let drawable = GLMapDrawable()
        drawable.transformMode = .custom
        drawable.rotatesWithMap = true
        drawable.scale = Double(GLMapPointMax / (tilesForZoom * 256))
        drawable.position = GLMapPoint(x: Double(tileSize * tilePosX), y: Double((tilesForZoom - tilePosY - 1) * tileSize))
        map.add(drawable)
        
        if let url = URL(string: "https://tile.openstreetmap.org/3/4/2.png") {
            loadImage(atUrl: url, intoDrawable: drawable)
        }
    }
    
    func drawableImageWithDrawOrder() {
        // original tile url is https://tile.openstreetmap.org/3/4/3.png
        // we'll show how to calculate it's position on map in GLMapPoints
        let tilePosZ:Int32 = 3, tilePosX:Int32 = 4, tilePosY:Int32 = 3
        
        // world size divided to number of tiles at this zoom level
        let tilesForZoom : Int32 = 1 << tilePosZ
        let tileSize = GLMapPointMax / tilesForZoom;
        
        // Drawables created with DrawOrder displayed on top of the map. Draw order is used to sort drawables.
        let drawable = GLMapDrawable(drawOrder:0)
        drawable.transformMode = .custom
        drawable.rotatesWithMap = true
        drawable.scale = Double(GLMapPointMax / (tilesForZoom * 256))
        drawable.position = GLMapPoint(x: Double(tileSize * tilePosX), y: Double((tilesForZoom - tilePosY - 1) * tileSize))
        map.add(drawable)
        
        if let url = URL(string: "https://tile.openstreetmap.org/3/4/3.png") {
            loadImage(atUrl: url, intoDrawable: drawable)
        }
    }
    
    func loadImage(atUrl url:URL, intoDrawable drawable:GLMapDrawable) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let image = UIImage(data: data) {
                    drawable.setImage(image, for: self.map, completion: nil)
                }
            }
        }.resume()
    }
    
    @objc func addImageButtonTap(_ sender: Any) {
        if let button = sender as? UIBarButtonItem {
            if let title = button.title {
                switch title {
                case "Add image":
                    mapDrawable.hidden = false
                    mapDrawable.position = map.mapCenter
                    mapDrawable.angle = Float(arc4random_uniform(360))

                    button.title = "Move image"
                case "Move image":
                    map.animate({ _ in
                        self.mapDrawable.position = self.map.mapCenter
                        self.mapDrawable.angle = Float(arc4random_uniform(360))
                    })
                    button.title = "Remove image"
                case "Remove image":
                    mapDrawable.hidden = true
                    button.title = "Add image"
                default: break
                }
            }
        }
    }

    var menuPos: CGPoint?

    var pins: ImageGroup?
    var mapImageGroup: GLMapImageGroup?
    var pinToDelete: Pin?

    func multiImageDemo() {
        displayAlert(nil, message: "Long tap on map to add pin, tap on pin to remove it")

        map.longPressGestureBlock = { [weak self] (point: CGPoint) in
            let menu = UIMenuController.shared
            if !menu.isMenuVisible {
                self?.menuPos = point
                self?.becomeFirstResponder()

                if let map = self?.map {
                    menu.setTargetRect(CGRect(origin: point, size: CGSize(width: 1, height: 1)), in: map)
                    menu.menuItems = [UIMenuItem(title: "Add pin", action: #selector(MapViewController.addPin))]
                    menu.setMenuVisible(true, animated: true)
                }
            }
        }

        map.tapGestureBlock = { [weak self] (point: CGPoint) in

            if let pins = self?.pins, let map = self?.map {
                if let pin = pins.findPin(point: point, mapView: map) {
                    let menu = UIMenuController.shared
                    if !menu.isMenuVisible {
                        let pinPos = map.makeDisplayPoint(from: pin.position)
                        self?.pinToDelete = pin
                        self?.becomeFirstResponder()
                        menu.setTargetRect(CGRect(origin: CGPoint(x: pinPos.x, y: pinPos.y - 20.0), size: CGSize(width: 1, height: 1)), in: map)
                        menu.menuItems = [UIMenuItem(title: "Delete pin", action: #selector(MapViewController.deletePin))]
                        menu.setMenuVisible(true, animated: true)
                    }
                }
            }
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    @objc func addPin() {
        if pins == nil {
            pins = ImageGroup()
        }

        if mapImageGroup == nil {
            mapImageGroup = GLMapImageGroup(callback: pins!, andDrawOrder: 3)
            map.add(mapImageGroup!)
        }

        let pinPos = map.makeMapPoint(fromDisplay: menuPos!)
        let pin = Pin(position: pinPos, imageID: UInt32(pins!.count() % 3))
        pins?.append(pin)
        mapImageGroup?.setNeedsUpdate(false)
    }

    @objc func deletePin() {
        if pinToDelete != nil {
            pins?.remove(pinToDelete!)
            mapImageGroup?.setNeedsUpdate(false)
        }

        if mapImageGroup != nil && pins != nil && pins?.count() == 0 {
            map.remove(mapImageGroup!)
            mapImageGroup = nil
            pins = nil
        }
    }

    func markerLayer() {
        // Create marker image
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svgpb") {
            if let image = GLMapVectorImageFactory.shared.image(fromSvgpb: imagePath, withScale: 0.2) {
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
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
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

    func markerLayerWithClustering() {
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svgpb") {
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
                if let image = GLMapVectorImageFactory.shared.image(fromSvgpb: imagePath, withScale: scale, andTintColor: tintColors[i]) {
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
                        if let name = nameValue.asString(){
                            data.setText(name, offset: CGPoint(x: 0, y: 8), style: textStyle!)
                        }
                    }
                }
            }

            // Union fill block used to set style for cluster object. First param is number objects inside the cluster and second is marker object.
            styleCollection.setMarkerUnionFill({ markerCount, data in
                // we have 8 marker styles for 1, 2, 4, 8, 16, 32, 64, 128+ markers inside
                var markerStyle = Int(log2(Double(markerCount)))
                if markerStyle >= tintColors.count {
                    markerStyle = tintColors.count - 1
                }
                data.setStyle(UInt(markerStyle))
                data.setText("\(markerCount)", offset: CGPoint.zero, style: textStyle!)
            })

            // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on main thread only when data is loaded.
            DispatchQueue.global().async {
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json") {
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        let markerLayer = GLMapMarkerLayer(vectorObjects: objects, andStyles: styleCollection, clusteringRadius: maxWidth / 2, drawOrder: 2)
                        let bbox = objects.bbox

                        DispatchQueue.main.async { [weak self] in
                            if let wself = self {
                                let map = wself.map
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

    func markerLayerWithMapCSSClustering() {
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svgpb") {
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
                if let image = GLMapVectorImageFactory.shared.image(fromSvgpb: imagePath, withScale: scale, andTintColor: tintColors[i]) {
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
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        if let cascadeStyle = GLMapVectorCascadeStyle.createStyle(
                            "node { icon-image:\"uni0\"; text-priority: 100; text:eval(tag(\"name\")); text-color:#2E2D2B; font-size:12; font-stroke-width:1pt; font-stroke-color:#FFFFFFEE;}" +
                                "node[count>=2]{icon-image:\"uni1\"; text-priority: 101; text:eval(tag(\"count\"));}" +
                                "node[count>=4]{icon-image:\"uni2\"; text-priority: 102;}" +
                                "node[count>=8]{icon-image:\"uni3\"; text-priority: 103;}" +
                                "node[count>=16]{icon-image:\"uni4\"; text-priority: 104;}" +
                                "node[count>=32]{icon-image:\"uni5\"; text-priority: 105;}" +
                                "node[count>=64]{icon-image:\"uni6\"; text-priority: 106;}" +
                                "node[count>=128]{icon-image:\"uni7\"; text-priority: 107;}") {
                            let markerLayer = GLMapMarkerLayer(vectorObjects: objects, cascadeStyle: cascadeStyle, styleCollection: styleCollection, clusteringRadius: maxWidth / 2, drawOrder: 2)
                            let bbox = objects.bbox
                            DispatchQueue.main.async { [weak self] in
                                if let wself = self {
                                    let map = wself.map
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
    }

    func multiLineDemo() {
        let multiline = GLMapVectorObject()

        let line1 = [
            GLMapGeoPoint(lat: 53.8869, lon: 27.7151), // Minsk
            GLMapGeoPoint(lat: 50.4339, lon: 30.5186), // Kiev
            GLMapGeoPoint(lat: 52.2251, lon: 21.0103), // Warsaw
            GLMapGeoPoint(lat: 52.5037, lon: 13.4102), // Berlin
            GLMapGeoPoint(lat: 48.8505, lon: 2.3343),
        ] // Paris

        multiline.addGeoLine(line1)

        let line2 = [
            GLMapGeoPoint(lat: 52.3690, lon: 4.9021), // Amsterdam
            GLMapGeoPoint(lat: 50.8263, lon: 4.3458), // Brussel
            GLMapGeoPoint(lat: 49.6072, lon: 6.1296),
        ] // Luxembourg

        multiline.addGeoLine(line2)

        if let style = GLMapVectorCascadeStyle.createStyle("line{width: 2pt; color:green;}") {
            let drawable = GLMapDrawable()
            drawable.setVectorObject(multiline, with: style, completion: nil)
            map.add(drawable)
        }
    }

    func polygonDemo() {
        func fillPoints(centerPoint: GLMapGeoPoint, radius: Double) -> Array<GLMapGeoPoint> {
            let pointCount = 25
            let sectorSize = 2 * Double.pi / Double(pointCount)

            var circlePoints: Array<GLMapGeoPoint> = []
            for i in 0 ..< pointCount {
                circlePoints.append(GLMapGeoPoint(lat: centerPoint.lat + cos(sectorSize * Double(i)) * radius,
                                                  lon: centerPoint.lon + sin(sectorSize * Double(i)) * radius))
            }
            return circlePoints
        }

        let polygon = GLMapVectorObject()
        let centerPoint = GLMapGeoPointMake(53, 27)

        polygon.addGeoPolygonOuterRing(fillPoints(centerPoint: centerPoint, radius: 10))

        polygon.addGeoPolygonInnerRing(fillPoints(centerPoint: centerPoint, radius: 5))

        if let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#10106050; width:4pt; color:green;}") {
            let drawable = GLMapDrawable()
            drawable.setVectorObject(polygon, with: style, completion: nil)
            map.add(drawable)
        }
        map.mapGeoCenter = centerPoint
    }

    func geoJsonDemoPostcodes() {
        guard let path = Bundle.main.path(forResource: "uk_postcodes", ofType: "geojson") else {
            return
        }
        
        do {
            let geojson = try String.init(contentsOfFile: path)
            
            guard let objects = GLMapVectorObject.createVectorObjects(fromGeoJSON: geojson) else {
                return
            }
            guard let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:green; width:1pt; color:red;}") else {
                return
            }
            
            let drawable = GLMapDrawable()
            drawable.setVectorObjects(objects, with: style, completion: nil)
            map.add(drawable)
            
            let bbox = objects.bbox
            map.mapCenter = bbox.center
            map.mapZoom = map.mapZoom(for: bbox)
        } catch let error {
            displayAlert(nil, message: "GeoJSON loading error: \(error.localizedDescription)")
            return
        }
    }
    
    func geoJsonDemo() {
        if let objects = GLMapVectorObject.createVectorObjects(fromGeoJSON: "[{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [30.5186, 50.4339]}, \"properties\": {\"id\": \"1\", \"text\": \"test1\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [27.7151, 53.8869]}, \"properties\": {\"id\": \"2\", \"text\": \"test2\"}}," +
            "{\"type\":\"LineString\",\"coordinates\": [ [27.7151, 53.8869], [30.5186, 50.4339], [21.0103, 52.2251], [13.4102, 52.5037], [2.3343, 48.8505]]}," +
            "{\"type\":\"Polygon\",\"coordinates\":[[ [0.0, 10.0], [10.0, 10.0], [10.0, 20.0], [0.0, 20.0] ],[ [2.0, 12.0], [ 8.0, 12.0], [ 8.0, 18.0], [2.0, 18.0] ]]}]") {
            if let style = GLMapVectorCascadeStyle.createStyle("node[id=1]{icon-image:\"bus.svgpb\";icon-scale:0.5;icon-tint:green;text:eval(tag('text'));text-color:red;font-size:12;text-priority:100;}" +
                "node|z-9[id=2]{icon-image:\"bus.svgpb\";icon-scale:0.7;icon-tint:blue;;text:eval(tag('text'));text-color:red;font-size:12;text-priority:100;}" +
                "line{linecap: round; width: 5pt; color:blue; layer:100;}" +
                "area{fill-color:green; width:1pt; color:red; layer:100;}") {

                var drawable = GLMapDrawable()
                drawable.setVectorObject(objects[0], with: style, completion: nil)
                map.add(drawable)
                flashObject(object: drawable)
                objects.removeObject(at: 0);

                drawable = GLMapDrawable()
                drawable.setVectorObjects(objects, with: style, completion: nil)
                map.add(drawable)
            }
        }
    }

    var flashAdd: Bool = false
    @objc func flashObject(object: GLMapDrawable) {
        if flashAdd {
            map.add(object)
        } else {
            map.remove(object)
        }
        flashAdd = !flashAdd
        perform(#selector(MapViewController.flashObject), with: object, afterDelay: 1)
    }

    func screenshotDemo() {
        NSLog("Start capturing frame")
        map.captureFrame { [weak self] (image: UIImage?) in
            if image != nil {
                NSLog("Image captured \(String(describing: image))")
                let alert = UIAlertController(title: nil, message: "Image captured \(String(describing: image))", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

                self?.present(alert, animated: true, completion: nil)
            }
        }
    }

    func fontsDemo() {
        if let objects = GLMapVectorObject.createVectorObjects(fromGeoJSON:
            "[{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 64]}, \"properties\": {\"id\": \"1\"}}," +
                "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 63.6]}, \"properties\": {\"id\": \"2\"}}," +
                "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 62.3]}, \"properties\": {\"id\": \"3\"}}," +
                "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 61]}, \"properties\": {\"id\": \"4\"}}," +
                "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 60]}, \"properties\": {\"id\": \"5\"}}," +
                "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 58]}, \"properties\": {\"id\": \"6\"}}," +
                "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 56]}, \"properties\": {\"id\": \"7\"}}," +
                "{\"type\":\"Polygon\",\"coordinates\":[[ [-30, 50], [-30, 80], [-10, 80], [-10, 50] ]]}]") {
            if let style = GLMapVectorCascadeStyle.createStyle(
                "node[id=1]{text:'Test12';text-color:black;font-size:5;text-priority:100;}" +
                    "node[id=2]{text:'Test12';text-color:black;font-size:10;text-priority:100;}" +
                    "node[id=3]{text:'Test12';text-color:black;font-size:15;text-priority:100;}" +
                    "node[id=4]{text:'Test12';text-color:black;font-size:20;text-priority:100;}" +
                    "node[id=5]{text:'Test12';text-color:black;font-size:25;text-priority:100;}" +
                    "node[id=6]{text:'Test12';text-color:black;font-size:30;text-priority:100;}" +
                    "node[id=7]{text:'Test12';text-color:black;font-size:35;text-priority:100;}" +
                    "area{fill-color:white; layer:100;}") {
                let drawable = GLMapDrawable()
                drawable.setVectorObjects(objects, with: style, completion: nil)
                map.add(drawable)
            }
        }

        let testView = UIView(frame: CGRect(x: 350, y: 200, width: 150, height: 200))
        testView.backgroundColor = UIColor.black

        let testView2 = UIView(frame: CGRect(x: 200, y: 200, width: 150, height: 200))
        testView2.backgroundColor = UIColor.white

        var y: CGFloat = 0.0

        for i in 0 ... 6 {
            let font = UIFont.systemFont(ofSize: CGFloat(i * 5 + 5))
            let lbl = UILabel()
            lbl.text = "Test12"
            lbl.font = font
            lbl.textColor = UIColor.white
            lbl.sizeToFit()
            lbl.frame = CGRect(origin: CGPoint(x: 0, y: y), size: lbl.frame.size)
            testView.addSubview(lbl)

            let lbl2 = UILabel()
            lbl2.text = "Test12"
            lbl2.font = font
            lbl2.textColor = UIColor.black
            lbl2.sizeToFit()
            lbl2.frame = CGRect(origin: CGPoint(x: 0, y: y), size: lbl2.frame.size)
            testView2.addSubview(lbl2)

            y += lbl.frame.size.height
        }

        map.addSubview(testView)
        map.addSubview(testView2)
    }

    func flyToDemo() {
        let barButton = UIBarButtonItem(title: "Fly", style: .plain, target: self, action: #selector(MapViewController.flyTo))
        navigationItem.rightBarButtonItem = barButton

        GLMapManager.shared.tileDownloadingAllowed = true

        map.animate { animation in
            self.map.mapZoomLevel = 14
            animation.fly(to: GLMapGeoPoint(lat: 37.3257, lon: -122.0353))
        }
    }

    @objc func flyTo() {
        map.animate { animation in
            self.map.mapZoomLevel = 14
            let minPt = GLMapGeoPoint(lat: 33, lon: -118)
            let maxPt = GLMapGeoPoint(lat: 48, lon: -85)
            animation.fly(to: GLMapGeoPoint(lat: minPt.lat + (maxPt.lat - minPt.lat) * drand48(),
                                            lon: minPt.lon + (maxPt.lon - minPt.lon) * drand48()))
        }
    }

    func styleReloadDemo() {
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: navigationController!.navigationBar.frame.size.width, height: 21))
        textField.placeholder = "Enter style URL"
        navigationItem.titleView = textField

        textField.becomeFirstResponder()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reload style", style: .plain, target: self, action: #selector(styleReload))
    }

    func tilesBulkDownload() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Download", style: .plain, target: self, action: #selector(startBulkDownload))
        map.mapCenter = GLMapPointMakeFromGeoCoordinates(53, 27)
        map.mapZoom = pow(2, 12.5)
    }

    @objc func startBulkDownload() {
        let bbox = map.bbox
        let manager = GLMapManager.shared
        let allTiles = manager.vectorTiles(at: bbox)

        let niceTileGridVisualization = true
        if niceTileGridVisualization {
            if allTiles.count > 100_000 {
                NSLog("Too many tiles")
                return
            }

            let notCachedTiles = manager.notCachedVectorTiles(at: bbox)
            NSLog("Total tiles %d tiles to cache: %d", allTiles.count, notCachedTiles.count)

            let notDownloadedTiles = GLMapVectorObject()
            let downloadedTiles = GLMapVectorObject()

            for tile in allTiles {
                let tileBBox = manager.bbox(forTile: tile.uint64Value)

                let pts = [
                    tileBBox.origin,
                    GLMapPointMake(tileBBox.origin.x, tileBBox.origin.y + tileBBox.size.y),
                    GLMapPointMake(tileBBox.origin.x + tileBBox.size.x, tileBBox.origin.y + tileBBox.size.y),
                    GLMapPointMake(tileBBox.origin.x + tileBBox.size.x, tileBBox.origin.y),
                    tileBBox.origin,
                ]

                if notCachedTiles.contains(tile) {
                    notDownloadedTiles.addPolygonOuterRing(pts)
                } else {
                    downloadedTiles.addPolygonOuterRing(pts)
                }
            }

            let downloaded = GLMapDrawable(drawOrder: 4)
            downloaded.setVectorObject(downloadedTiles, with: GLMapVectorCascadeStyle.createStyle("area{width: 2pt; color: green;}")!, completion: nil)
            map.add(downloaded)

            let notDownloaded = GLMapDrawable(drawOrder: 5)
            notDownloaded.setVectorObject(downloadedTiles, with: GLMapVectorCascadeStyle.createStyle("area{width: 2pt; color: red;}")!, completion: nil)
            map.add(notDownloaded)
        }

        tilesToDownload = allTiles.count
        manager.cacheTiles(allTiles) { (tile, error) -> Bool in
            NSLog("Tile downloaded:%llu error:%@", tile, error?.localizedDescription ?? "no error")
            self.tilesToDownload -= 1
            if self.tilesToDownload == 0 {
                DispatchQueue.main.async {
                    self.map.reloadTiles()
                }
            }
            return true
        }
    }

    @objc func styleReload() {
        let urlField = navigationItem.titleView as! UITextField

        do {
            let styleData = try Data(contentsOf: URL(string: urlField.text!)!)
            if map.loadStyle({ (name) -> GLMapResource in
                if name == "Style.mapcss" {
                    return GLMapResourceWithData(styleData)
                }

                return GLMapResourceEmpty
            }) {
                map.reloadTiles()
            } else {
                displayAlert(nil, message: "Style syntax error. Check log for details.")
            }
        } catch let error as NSError {
            displayAlert(nil, message: "Style downloading error: \(error.localizedDescription)")
        }
    }

    func displayAlert(_ title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func recordGPSTrack() {
        // we'll forward location back to mapView. I promise.
        locationManager.delegate = self
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Forward events to GLMapView
        map.locationManager(manager, didUpdateLocations: locations)

        for location in locations {
            let mapPoint = GLMapPointMakeFromGeoCoordinates(location.coordinate.latitude, location.coordinate.longitude)
            var trackPoint = GLTrackPoint(pt: mapPoint, color: GLMapColor(red: 255, green: 255, blue: 0, alpha: 255))

            if trackData != nil {
                trackData = GLMapTrackData(data: trackData!, andNewPoint: trackPoint, startNewSegment: false)
            } else {
                trackData = GLMapTrackData(points: &trackPoint, count: 1)
            }
        }

        if track == nil {
            track = GLMapTrack(drawOrder: 2, andTrackData: trackData)
            track?.setStyle(GLMapVectorStyle.createStyle("{width:5pt;}"))
            map.add(track!)
        } else {
            track?.setTrackData(trackData!)
        }
    }
}
