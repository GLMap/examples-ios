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

class MapViewController: MapViewWithUserLocation {
    let downloadButton = UIButton(type: .system)

    var trackData: GLMapTrackData?
    var track: GLMapTrack?
    var trackStyle: GLMapVectorStyle?

    typealias Demo = ViewController.Demo

    var currentDemo: Demo = .offlineMap

    let demoCases = [
        Demo.offlineMap: showOfflineMap,
        Demo.darkTheme: loadDarkTheme,
        Demo.embeddMap: showEmbedMap,
        Demo.onlineMap: showOnlineMap,
        Demo.routing: testRouting,
        Demo.rasterOnlineMap: showRasterOnlineMap,
        Demo.zoomToBBox: zoomToBBox,
        Demo.offlineSearch: offlineSearch,
        Demo.notifications: testNotifications,
        Demo.singleImage: singleImageDemo,
        Demo.multiImage: multiImageDemo,
        Demo.markerLayer: markerLayer,
        Demo.markerLayerWithClustering: markerLayerWithClustering,
        Demo.markerLayerWithMapCSSClustering: markerLayerWithMapCSSClustering,
        Demo.multiLine: multiLineDemo,
        Demo.track: recordGPSTrack,
        Demo.polygon: polygonDemo,
        Demo.geoJSON: geoJsonDemoPostcodes,
        Demo.screenshot: screenshotDemo,
        Demo.fonts: fontsDemo,
        Demo.flyTo: flyToDemo,
        Demo.downloadInBBox: downloadInBBox,
        Demo.styleReload: styleReloadDemo,
    ]

    var tilesToDownload: Int = 0
    var stylePath: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        if let path = GLMapManager.shared.resourcesBundle.path(forResource: "DefaultStyle", ofType: "bundle") {
            stylePath = path
        } else {
            print("Missing DefaultStyle.bundle inside main bundle")
            return
        }

        title = "Demo map"
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactScrollEdgeAppearance = appearance
        }

        downloadButton.setTitle("Download Map", for: .normal)
        downloadButton.addTarget(self, action: #selector(MapViewController.downloadButtonTap), for: .touchUpInside)
        view.addSubview(downloadButton)

        downloadButton.center = view.center

        updateDownloadButton()

        map.centerTileStateChangedBlock = { [weak self] in
            self?.updateDownloadButton()
        }

        map.mapDidMoveBlock = { [weak self] _ in
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
        default:
            break
        }
    }

    var mapToDownload: GLMapInfo?

    func updateDownloadButtonText() {
        if map.centerTileState == .noData {
            guard let maps = GLMapManager.shared.maps(at: map.mapCenter), maps.count > 0 else {
                mapToDownload = nil
                return
            }

            for map in maps {
                if map.state(for: .map) == .downloaded {
                    mapToDownload = nil
                    break
                } else {
                    mapToDownload = map
                }
            }

            if let mapToDownload {
                let title: String
                if let task = GLMapManager.shared.downloadTask(forMap: mapToDownload, dataSet: .map) {
                    let progress = task.downloaded * 100 / task.total
                    title = String(format: "Downloading %@ %d%%", mapToDownload.name(), progress)
                } else {
                    title = "Download \(mapToDownload.name())"
                }
                downloadButton.setTitle(title, for: .normal)
            } else {
                downloadButton.setTitle("Download Maps", for: .normal)
            }
        }
    }

    @objc func downloadButtonTap() {
        if let mapToDownload {
            let downloadTask = GLMapManager.shared.downloadTask(forMap: mapToDownload, dataSet: .map)
            if let task = downloadTask {
                task.cancel()
            } else {
                GLMapManager.shared.downloadDataSets(.all, forMap: mapToDownload, withCompletionBlock: nil)
            }
        } else {
            performSegue(withIdentifier: "DownloadMaps", sender: self)
        }
    }

    // MARK: Demo functions

    func showOfflineMap() {
        // nonthing to do
    }

    func loadDarkTheme() {
        loadStyle(darkTheme: true, carDriving: false)
    }

    func showEmbedMap() {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.add(.map, path: mapPath, bbox: .empty)
            map.mapGeoCenter = GLMapGeoPoint(lat: 42.4341, lon: 19.26)
            map.mapZoomLevel = 14
        }
    }

    var routingMode: UISegmentedControl?
    var networkMode: UISegmentedControl?
    var startPoint = GLMapGeoPoint(lat: 53.844720, lon: 27.482352)
    var endPoint = GLMapGeoPoint(lat: 53.931935, lon: 27.583995)
    var menuPoint: GLMapGeoPoint?
    var routeTrack: GLMapTrack?
    var valhallaConfig: String?

    func testRouting() {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        if let style = parser.parseFromResources() {
            map.setStyle(style)
        }

        guard let valhallaConfigPath = Bundle.main.path(forResource: "valhalla", ofType: "json") else {
            NSLog("Can't find valhalla.json in resources")
            return
        }

        do {
            valhallaConfig = try String(contentsOfFile: valhallaConfigPath)
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
        bbox.add(point: GLMapPoint(geoPoint: startPoint))
        bbox.add(point: GLMapPoint(geoPoint: endPoint))
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox) / 2

        map.tapGestureBlock = { [weak self] gesure in
            guard let self else { return }
            let menu = UIMenuController.shared
            if !menu.isMenuVisible {
                let pt = gesure.location(in: map)
                menuPoint = GLMapGeoPoint(point: map.makeMapPoint(fromDisplay: pt))
                becomeFirstResponder()
                menu.menuItems = [
                    UIMenuItem(title: "Departure", action: #selector(MapViewController.setDeparture)),
                    UIMenuItem(title: "Destination", action: #selector(MapViewController.setDestination)),
                ]
                menu.showMenu(from: map, rect: CGRect(x: pt.x, y: pt.y, width: 1, height: 1))
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
        guard let valhallaConfig else { return }

        let routeRequest = GLRouteRequest()

        if routingMode?.selectedSegmentIndex == 0 {
            routeRequest.setAutoWithOptions(CostingOptionsAuto())
        } else if routingMode?.selectedSegmentIndex == 1 {
            routeRequest.setBicycleWithOptions(CostingOptionsBicycle())
        } else {
            routeRequest.setPedestrianWithOptions(CostingOptionsPedestrian())
        }

        routeRequest.add(GLRoutePoint(pt: startPoint, heading: Double.nan, type: .break))
        routeRequest.add(GLRoutePoint(pt: endPoint, heading: Double.nan, type: .break))

        let routeStyle = GLMapVectorStyle.createStyle("{width: 7pt; fill-image:\"track-arrow.svg\";}")!

        let requestCompletion: GLRouteRequestCompletionBlock = { [weak self] (result: GLRoute?, error: Error?) in
            guard let self else { return }
            if let result, let trackData = result.trackData(with: GLMapColor(red: 50, green: 200, blue: 0, alpha: 200)) {
                if routeTrack == nil {
                    let track = GLMapTrack(drawOrder: 5)
                    map.add(track)
                    routeTrack = track
                }
                routeTrack?.setData(trackData, style: routeStyle)
            }
            if let error {
                displayAlert("Routing error", message: error.localizedDescription)
            }
        }

        if networkMode?.selectedSegmentIndex != 0 {
            routeRequest.startOffline(withConfig: valhallaConfig, completion: requestCompletion)
        } else {
            routeRequest.startOnline(completion: requestCompletion)
        }
    }

    func showOnlineMap() {
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14
    }

    func showRasterOnlineMap() {
        if let osmTileSource = OSMTileSource(cachePath: "/osm.sqlite") {
            map.base = osmTileSource
        }
    }

    func zoomToBBox() {
        // get pixel coordinates of geo points
        var bbox = GLMapBBox.empty

        bbox.add(point: GLMapPoint(lat: 52.5037, lon: 13.4102))
        bbox.add(point: GLMapPoint(lat: 53.9024, lon: 27.5618))

        // set center point and change zoom to make screenDistance less or equal mapView.bounds
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox)
    }

    func offlineSearch() {
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

            searchOffline.searchAsync(completionBlock: { [weak self] results in
                self?.displaySearchResults(results: results)
            })
        }
    }

    func displaySearchResults(results: GLMapVectorObjectArray) {
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
            map.mapScale = map.mapScale(for: bbox)
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

    var mapImage = GLMapImage(drawOrder: 3)

    func singleImageDemo() {
        if let image = UIImage(named: "pin1.png", in: nil, compatibleWith: nil) {
            mapImage.setImage(image)
            // We set offset to the bottom-center to attach pin point to the map
            mapImage.offset = CGPoint(x: image.size.width / 2, y: 0)
            mapImage.hidden = true
            map.add(mapImage)
        }

        // we'll just add button for this demo
        let barButton = UIBarButtonItem(title: "Add image", style: .plain, target: self, action: #selector(MapViewController.addImageButtonTap))
        navigationItem.rightBarButtonItem = barButton
        addImageButtonTap(barButton)

        drawRasterTile()
    }

    func drawRasterTile() {
        // original tile url is https://tile.openstreetmap.org/3/4/2.png
        // we'll show how to calculate it's position on map in GLMapPoints
        let tilePosZ: Int32 = 3, tilePosX: Int32 = 4, tilePosY: Int32 = 2

        // world size divided to number of tiles at this zoom level
        let tilesForZoom: Int32 = 1 << tilePosZ
        let tileSize = GLMapPointMax / tilesForZoom

        // Drawables created using default constructor is added on map as polygon with layer:0; and z-index:0;
        let mapImage = GLMapImage()
        mapImage.transformMode = .custom
        mapImage.rotatesWithMap = true
        mapImage.scale = Double(GLMapPointMax / (tilesForZoom * 256))
        mapImage.position = GLMapPoint(x: Double(tileSize * tilePosX), y: Double((tilesForZoom - tilePosY - 1) * tileSize))
        map.add(mapImage)

        if let url = URL(string: "https://tile.openstreetmap.org/3/4/2.png") {
            loadImage(atUrl: url, intoDrawable: mapImage)
        }
    }

    func loadImage(atUrl url: URL, intoDrawable drawable: GLMapImage) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data, let image = UIImage(data: data) {
                drawable.setImage(image)
            }
        }.resume()
    }

    @objc func addImageButtonTap(_ button: UIBarButtonItem) {
        switch button.title {
        case "Add image":
            mapImage.hidden = false
            mapImage.position = map.mapCenter
            mapImage.angle = Float(arc4random_uniform(360))

            button.title = "Move image"
        case "Move image":
            map.animate { _ in
                mapImage.position = map.mapCenter
                mapImage.angle = Float(arc4random_uniform(360))
            }
            button.title = "Remove image"
        case "Remove image":
            mapImage.hidden = true
            button.title = "Add image"
        default: break
        }
    }

    var menuPos: CGPoint?

    var pins: ImageGroup?
    var mapImageGroup: GLMapImageGroup?
    var pinToDelete: Pin?

    func multiImageDemo() {
        displayAlert(nil, message: "Long tap on map to add pin, tap on pin to remove it")

        map.longPressGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let menu = UIMenuController.shared
            if !menu.isMenuVisible {
                let pt = gesture.location(in: map)
                menuPos = pt
                becomeFirstResponder()
                if let map {
                    menu.menuItems = [UIMenuItem(title: "Add pin", action: #selector(MapViewController.addPin))]
                    menu.showMenu(from: map, rect: CGRect(origin: pt, size: CGSize(width: 1, height: 1)))
                }
            }
        }

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            if let pins = pins, let pin = pins.findPin(point: gesture.location(in: map), mapView: map) {
                let menu = UIMenuController.shared
                if !menu.isMenuVisible {
                    let pinPos = map.makeDisplayPoint(from: pin.position)
                    pinToDelete = pin
                    becomeFirstResponder()
                    menu.menuItems = [UIMenuItem(title: "Delete pin", action: #selector(MapViewController.deletePin))]
                    menu.showMenu(from: map, rect: CGRect(origin: CGPoint(x: pinPos.x, y: pinPos.y - 20.0), size: CGSize(width: 1, height: 1)))
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
            let imageGroup = GLMapImageGroup(callback: pins!, andDrawOrder: 3)
            map.add(imageGroup)
            mapImageGroup = imageGroup
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

        if mapImageGroup != nil, pins != nil, pins?.count() == 0 {
            map.remove(mapImageGroup!)
            mapImageGroup = nil
            pins = nil
        }
    }

    func markerLayer() {
        // Create marker image
        guard let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg"),
              let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: 0.2) else { return }

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
        if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json"),
           let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath)
        {
            // Put our array of objects into marker layer. It could be any custom array of objects.
            // Disable clustering in this demo
            let markerLayer = GLMapMarkerLayer(vectorObjects: objects, andStyles: style, clusteringRadius: 0, drawOrder: 2)
            // Add marker layer on map
            map.add(markerLayer)
            let bbox = objects.bbox
            map.mapCenter = bbox.center
            map.mapScale = map.mapScale(for: bbox)
        }
    }

    func markerLayerWithClustering() {
        guard let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg") else { return }
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

        let styleCollection = GLMapMarkerStyleCollection()

        var maxWidth = 0.0
        for (i, color) in tintColors.enumerated() {
            let scale = 0.2 + 0.1 * Double(i)
            if let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: scale, andTintColor: color) {
                maxWidth = max(maxWidth, Double(image.size.width))
                styleCollection.addStyle(with: image)
            }
        }

        let textStyle = GLMapVectorStyle.createStyle("{text-color:black;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}")!

        styleCollection.setMarkerDataFill { marker, data in
            if let obj = marker as? GLMapVectorObject {
                data.setStyle(0)
                if let name = obj.value(forKey: "name")?.asString() {
                    data.setText(name, offset: CGPoint(x: 0, y: 8), style: textStyle)
                }
            }
        }

        styleCollection.setMarkerUnionFill { markerCount, data in
            var markerStyle = Int(log2(Double(markerCount)))
            markerStyle = min(markerStyle, tintColors.count - 1)
            data.setStyle(UInt32(markerStyle))
            data.setText("\(markerCount)", offset: .zero, style: textStyle)
        }

        DispatchQueue.global().async { [weak self] in
            if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json"),
               let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath)
            {
                let markerLayer = GLMapMarkerLayer(vectorObjects: objects, andStyles: styleCollection, clusteringRadius: maxWidth / 2, drawOrder: 2)
                let bbox = objects.bbox

                DispatchQueue.main.async {
                    self?.map?.add(markerLayer)
                    self?.map?.mapCenter = bbox.center
                    self?.map?.mapScale = self?.map?.mapScale(for: bbox) ?? 0
                }
            }
        }
    }

    func markerLayerWithMapCSSClustering() {
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
                            DispatchQueue.main.async { [weak self] in
                                if let map = self?.map {
                                    map.add(markerLayer)
                                    map.mapCenter = bbox.center
                                    map.mapScale = map.mapScale(for: bbox)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func multiLineDemo() {
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
            let vectorLayer = GLMapVectorLayer()
            vectorLayer.setVectorObject(GLMapVectorLine(lines: multiline), with: style)
            map.add(vectorLayer)
        }
    }

    func polygonDemo() {
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
            let vectorLayer = GLMapVectorLayer()
            vectorLayer.setVectorObject(GLMapVectorPolygon([outerRing], innerRings: [innerRing]), with: style)
            map.add(vectorLayer)
        }
        map.mapGeoCenter = centerPoint
    }

    func geoJsonDemoPostcodes() {
        guard let path = Bundle.main.path(forResource: "uk_postcodes", ofType: "geojson") else {
            return
        }

        title = "Tap on any UK region"

        do {
            let objects = try GLMapVectorObject.createVectorObjects(fromFile: path)
            let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:green; width:1pt; color:red;}")!

            let vectorLayer = GLMapVectorLayer()
            vectorLayer.setVectorObjects(objects, with: style)
            map.add(vectorLayer)

            let bbox = objects.bbox
            map.mapCenter = bbox.center
            map.mapScale = map.mapScale(for: bbox)

            map.tapGestureBlock = { [weak self] gesture in
                guard let self else { return }
                let mapPoint = map.makeMapPoint(fromDisplay: gesture.location(in: map))
                for index in 0 ..< objects.count {
                    let object = objects[index]
                    var pt = mapPoint
                    let tmp = map.makeMapPoint(fromDisplayDelta: CGPoint(x: 0, y: 10))
                    let maxDist = hypot(tmp.x, tmp.y)
                    // When checking polygons it will check if point is inside polygon. For lines and points it will check if distance is less then maxDistance.
                    if object.findNearestPoint(&pt, to: mapPoint, maxDistance: maxDist) {
                        displayAlert(nil, message: "Tap on object: \(object.debugDescription())")
                        return
                    }
                }
            }
        } catch {
            displayAlert(nil, message: "GeoJSON loading error: \(error.localizedDescription)")
            return
        }
    }

    func geoJsonDemo() {
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
        let busPin = GLMapVectorLayer()
        busPin.setVectorObject(objects[0], with: style, completion: nil)
        map.add(busPin)
        flashObject(busPin)

        objects.removeObject(at: 0)

        // add rest of the objects to the map
        let vectorLayer = GLMapVectorLayer()
        vectorLayer.setVectorObjects(objects, with: style, completion: nil)
        map.add(vectorLayer)
    }

    var flashAdd: Bool = false
    @objc func flashObject(_ object: GLMapDrawable) {
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

                self?.present(alert, animated: true)
            }
        }
    }

    func fontsDemo() {
        guard let objects = try? GLMapVectorObject.createVectorObjects(fromGeoJSON: """
        [{"type":"Feature","geometry":{"type":"Point","coordinates":[-25,64]},"properties":{"id":"1"}},
        {"type":"Feature","geometry":{"type":"Point","coordinates":[-25,63.6]},"properties":{"id":"2"}},
        {"type":"Feature","geometry":{"type":"Point","coordinates":[-25,62.3]},"properties":{"id":"3"}},
        {"type":"Feature","geometry":{"type":"Point","coordinates":[-25,61]},"properties":{"id":"4"}},
        {"type":"Feature","geometry":{"type":"Point","coordinates":[-25,60]},"properties":{"id":"5"}},
        {"type":"Feature","geometry":{"type":"Point","coordinates":[-25,58]},"properties":{"id":"6"}},
        {"type":"Feature","geometry":{"type":"Point","coordinates":[-25,56]},"properties":{"id":"7"}},
        {"type":"Polygon","coordinates":[[[-30,50],[-30,80],[-10,80],[-10,50]]]}]
        """),
            let style = GLMapVectorCascadeStyle.createStyle("""
            node {
                text:'Test12';
                text-color:black;
                text-priority:100;
            }
            node[id=1] {
                font-size:5;
            }
            node[id=2] {
                font-size:10;
            }
            node[id=3] {
                font-size:15;
            }
            node[id=4] {
                font-size:20;
            }
            node[id=5] {
                font-size:25;
            }
            node[id=6] {
                font-size:30;
            }
            node[id=7] {
                font-size:35;
            }
            area {
                fill-color:white;
                layer:100;
            }
            """) else { return }
        let drawable = GLMapVectorLayer()
        drawable.setVectorObjects(objects, with: style)
        map.add(drawable)

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
            animation.flyToMode = .enabled
            map.mapZoomLevel = 14
            map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        }
    }

    @objc func flyTo() {
        map.animate { animation in
            animation.flyToMode = .enabled
            map.mapZoomLevel = 14
            let minPt = GLMapGeoPoint(lat: 33, lon: -118)
            let maxPt = GLMapGeoPoint(lat: 48, lon: -85)
            map.mapGeoCenter = GLMapGeoPoint(lat: minPt.lat + (maxPt.lat - minPt.lat) * drand48(),
                                             lon: minPt.lon + (maxPt.lon - minPt.lon) * drand48())
        }
    }

    func styleReloadDemo() {
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: navigationController!.navigationBar.frame.size.width, height: 21))
        textField.placeholder = "Enter style URL"
        navigationItem.titleView = textField

        textField.becomeFirstResponder()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reload style", style: .plain, target: self, action: #selector(styleReload))
    }

    // MARK: BBox download

    var downloadBBox: GLMapBBox {
        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(lat: 53, lon: 27))
        bbox.add(point: GLMapPoint(lat: 53.5, lon: 27.5))
        return bbox
    }

    var mapPath: String {
        let cachesPath: NSString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        return cachesPath.appendingPathComponent("test.vmtar")
    }

    var navigationPath: String {
        let cachesPath: NSString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        return cachesPath.appendingPathComponent("test.navtar")
    }

    var elevationPath: String {
        let cachesPath: NSString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] as NSString
        return cachesPath.appendingPathComponent("test.eletar")
    }

    @objc
    private func downloadMapInBBox() {
        GLMapManager.shared.downloadDataSet(.map, path: mapPath, bbox: downloadBBox) { _, current, speed in
            NSLog("Download map stats: %d %f", current, speed)
        } completion: { [weak self] _ in
            self?.downloadInBBox()
        }
    }

    @objc
    private func downloadNavigationInBBox() {
        GLMapManager.shared.downloadDataSet(.navigation, path: navigationPath, bbox: downloadBBox) { _, current, speed in
            NSLog("Download nav stats: %d %f", current, speed)
        } completion: { [weak self] _ in
            self?.downloadInBBox()
        }
    }

    @objc
    private func downloadElevationInBBox() {
        GLMapManager.shared.downloadDataSet(.elevation, path: elevationPath, bbox: downloadBBox) { _, current, speed in
            NSLog("Download ele stats: %d %f", current, speed)
        } completion: { [weak self] _ in
            self?.downloadInBBox()
        }
    }

    func downloadInBBox() {
        let bbox = downloadBBox
        let manager = FileManager.default
        let mapManager = GLMapManager.shared

        var button: UIBarButtonItem?
        if manager.fileExists(atPath: elevationPath) {
            mapManager.add(.elevation, path: elevationPath, bbox: bbox)
        } else {
            button = UIBarButtonItem(title: "Download elevation", style: .plain, target: self, action: #selector(downloadElevationInBBox))
        }

        if manager.fileExists(atPath: navigationPath) {
            mapManager.add(.navigation, path: navigationPath, bbox: bbox)
        } else {
            button = UIBarButtonItem(title: "Download navigation", style: .plain, target: self, action: #selector(downloadNavigationInBBox))
        }

        if manager.fileExists(atPath: mapPath) {
            mapManager.add(.map, path: mapPath, bbox: bbox)
        } else {
            button = UIBarButtonItem(title: "Download map", style: .plain, target: self, action: #selector(downloadMapInBBox))
        }

        navigationItem.rightBarButtonItem = button

        map.enableClipping(bbox, minLevel: 9, maxLevel: 16)
        map.mapCenter = bbox.center
        map.drawElevationLines = true
        map.drawHillshades = true
        map.reloadTiles()
    }

    func loadStyle(darkTheme: Bool, carDriving: Bool) {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])

        var options = [String: String]()
        if carDriving {
            options["Style"] = "CarDriving"
        }
        if darkTheme {
            options["Theme"] = "Dark"
        }
        parser.setOptions(options, defaultValue: false)
        guard let style = parser.parseFromResources() else {
            NSLog("Can't parse style from resources")
            return
        }
        map.setStyle(style)
        map.reloadTiles()
    }

    @objc func styleReload() {
        guard
            let textView = navigationItem.titleView as? UITextField,
            let string = textView.text,
            let url = URL(string: string) else { return }

        do {
            let styleData = try Data(contentsOf: url)
            let parser = GLMapStyleParser(paths: [Bundle.main.bundlePath, stylePath])
            parser.parseNextBuffer(styleData)
            guard let style = parser.finish() else {
                displayAlert(nil, message: "Style syntax error. Check log for details.")
                return
            }

            map.setStyle(style)
            map.reloadTiles()
        } catch {
            displayAlert(nil, message: "Style downloading error: \(error.localizedDescription)")
        }
    }

    func displayAlert(_ title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

    func recordGPSTrack() {
        let track = GLMapTrack(drawOrder: 2)
        track.setData(trackData, style: GLMapVectorStyle.createStyle("{width:5pt;}")!)
        map.add(track)
        self.track = track
        trackStyle = GLMapVectorStyle.createStyle("{width:5pt;}")
    }

    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        super.locationManager(manager, didUpdateLocations: locations)
        guard let track, let trackStyle else { return }

        for location in locations {
            let mapPoint = GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            var trackPoint = GLTrackPoint(pt: mapPoint, color: GLMapColor(red: 255, green: 255, blue: 0, alpha: 255))

            if let curData = trackData {
                trackData = GLMapTrackData(data: curData, andNewPoint: trackPoint, startNewSegment: false)
            } else {
                trackData = GLMapTrackData(points: &trackPoint, count: 1)
            }
        }
        if let trackData {
            track.setData(trackData, style: trackStyle)
        }
    }
}
