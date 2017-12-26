//
//  MapViewController.swift
//  SwiftDemo
//
//  Created by Evgen Bodunov on 11/16/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import UIKit
import GLMap
import GLMapSwift

class MapViewController: UIViewController, CLLocationManagerDelegate {
    let map = GLMapView()
    let downloadButton = UIButton(type:.system)
    let locationManager = CLLocationManager.init()
    
    var trackData : GLMapTrackData? = nil
    var track : GLMapTrack? = nil

    typealias Demo = ViewController.Demo

    var currentDemo: Demo = .OfflineMap

    let demoCases = [
        Demo.OfflineMap: showOfflineMap,
        Demo.EmbeddMap: showEmbedMap,
        Demo.OnlineMap: showOnlineMap,
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
        Demo.GeoJSON: geoJsonDemo,
        Demo.Screenshot: screenshotDemo,
        Demo.Fonts: fontsDemo,
        Demo.FlyTo: flyToDemo,
        Demo.StyleReload: styleReloadDemo,
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.title = "Demo map"

        map.frame = self.view.bounds
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation() // don't forget to stop updating location
        locationManager.delegate = map

        map.showUserLocation = true

        self.view.addSubview(map)

        downloadButton.setTitle("Download Map", for: .normal)
        downloadButton.addTarget(self, action: #selector(MapViewController.downloadButtonTap), for: .touchUpInside)
        self.view.addSubview(downloadButton)

        downloadButton.center = self.view.center

        updateDownloadButton()

        map.centerTileStateChangedBlock = { [weak self] in
            self?.updateDownloadButton()
        }

        map.mapDidMoveBlock = { [weak self] (bbox: GLMapBBox) in
            self?.updateDownloadButtonText()
        }

        NotificationCenter.default.addObserver(forName: GLMapInfo.downloadProgress, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateDownloadButtonText()
        }

        NotificationCenter.default.addObserver(forName: GLMapInfo.downloadFinished, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.map.reloadTiles()
            self?.updateDownloadButton()
        }

        if let demo = demoCases[currentDemo] {
            demo(self)()
        } else {
            print("Missing demo for \(currentDemo)")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        // restore state before next demo
        GLMapManager.shared().tileDownloadingAllowed = false

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

            mapToDownload = GLMapManager.shared().map(at: mapCenter)

            if let map = mapToDownload {
                if map.state == .downloaded || map.distance(fromBorder: mapCenter) > 0.0 {
                    mapToDownload = nil
                }
            }

            if let map = mapToDownload {
                let downloadTask = GLMapManager.shared().downloadTask(forMap: map)

                let title: String
                if downloadTask != nil && map.state == .inProgress {
                    title = String.init(format:"Downloading %@ %d%%", map.name(), Int(map.downloadProgress * 100.0))
                } else {
                    title = "Download \(map.name())"
                }

                downloadButton.setTitle(title, for: .normal)
            } else {
                downloadButton.setTitle("Download Maps", for: .normal)
            }
        }
    }

    func downloadButtonTap() {
        if let map = mapToDownload {
            let downloadTask = GLMapManager.shared().downloadTask(forMap: map)
            if let task = downloadTask {
                task.cancel()
            } else {
                GLMapManager.shared().downloadMap(map, withCompletionBlock: nil)
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
            GLMapManager.shared().addMap(mapPath)

            map.move(to: GLMapGeoPoint.init(lat: 42.4341, lon: 19.26), zoomLevel: 14)
        }
    }

    func showOnlineMap() {
        GLMapManager.shared().tileDownloadingAllowed = true

        map.move(to: GLMapGeoPoint.init(lat: 37.3257, lon: -122.0353), zoomLevel: 14)
    }

    func showRasterOnlineMap() {
        if let osmTileSource = OSMTileSource(cachePath:"/osm.sqlite") {
            map.rasterTileSources = [osmTileSource]
        }
    }

    func zoomToBBox() {
        // get pixel coordinates of geo points
        var bbox = GLMapBBox.empty()

        bbox.addPoint(GLMapView.makeMapPoint(from: GLMapGeoPoint(lat:52.5037, lon:13.4102)))
        bbox.addPoint(GLMapView.makeMapPoint(from: GLMapGeoPoint(lat:53.9024, lon:27.5618)))
        
        // set center point and change zoom to make screenDistance less or equal mapView.bounds
        map.setMapCenter(bbox.center, zoom: map.mapZoom(for: bbox, viewSize: map.bounds.size))
    }
    
    var _categories: GLSearchCategories?
    // Return search categories that used to sort search results.
    func getCategories() -> GLSearchCategories{
        if(_categories == nil){
            //To compare string GLMap use ICU v56. It needs collation data (icudt56l.dat). You can place this line in main.m
            GLSearchCategories.setCollationDataLocation(Bundle.main.bundlePath);
            
            //Load preapred categories from biary file.
            _categories = GLSearchCategories.init(path: Bundle.main.path(forResource: "categories", ofType: "")!);
        }
        return _categories!;
    }
    
    func offlineSearch() {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared().addMap(mapPath)
            let center = GLMapGeoPoint.init(lat: 42.4341, lon: 19.26)
            map.move(to: center, zoomLevel: 14)
            
            
            let categories = getCategories();
            
            //Create new offline search request
            let searchOffline = GLSearchOffline.init();
            //Set search categories
            searchOffline.setCategories(categories);
            //Set center of search. Objects that is near center will recive bonus while sorting happens
            searchOffline.setCenter(GLMapPointMakeFromGeoCoordinates(center.lat, center.lon));
            //Set maximum number of results. By default is is 100
            searchOffline.setLimit(20);
            //Set locale settings. Used to boost results with locales native to user
            searchOffline.setLocaleSettings(map.localeSettings);
            
            let category = categories.categoriesStarted(with: ["food"], localeSettings: map.localeSettings);
            if(category.count != 0){
                let name = category[0].localizedName(map.localeSettings);
                NSLog("Searching %@", name ?? "no name");
                searchOffline.addCategoryFilter(category[0]);
            }
            //You can add more filters. For example by name
            //searchOffline.addNameFilter("cali"); //Add filter by name
            
            searchOffline.start(completionBlock: { (results) in
                DispatchQueue.main.async {
                    self.displaySearchResults(results: results);
                }
            });                        
        }
    }
    
    func displaySearchResults(results : [GLMapVectorObject]) {
        let styles = GLMapMarkerStyleCollection.init()
        styles.addStyle(with: GLMapVectorImageFactory.shared().image(fromSvgpb: Bundle.main.path(forResource: "cluster", ofType: "svgpb")!, withScale: 0.2, andTintColor: 0xFFFF0000)!)

        //If marker layer constructed using array with object of any type you need to set markerLocationBlock
        styles.setMarkerLocationBlock { (marker) -> GLMapPoint in
            if let obj = marker as? GLMapVectorObject {
                return obj.point;
            }
            return GLMapPoint.init();
        }

        // Data fill block used to set marker style and text
        // It could work with any user defined object type.
        // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
        styles.setMarkerDataFill { (marker, data) in
            data.setStyle(0)
        }

        let layer = GLMapMarkerLayer.init(markers: results, andStyles: styles, clusteringRadius:0, drawOrder:2);
        map.add(layer);
        
        if(results.count != 0){
            var bbox = GLMapBBox.empty();
            for object in results {
                bbox.addPoint(object.point);
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

    var mapImage: GLMapDrawable?

    func singleImageDemo() {
        if let image = UIImage.init(named: "pin1.png", in: nil, compatibleWith: nil) {
            mapImage = GLMapDrawable.init(drawOrder: 3)
            mapImage?.setImage(image, for: map, completion: nil);
            mapImage?.hidden = true
            map.add(mapImage!)
        }

        if mapImage == nil {
            return
        }

        // we'll just add button for this demo
        let barButton = UIBarButtonItem.init(title: "Add image", style: .plain, target: self, action: #selector(MapViewController.addImageButtonTap))

        self.navigationItem.rightBarButtonItem = barButton

        addImageButtonTap(barButton)
    }

    func addImageButtonTap(_ sender: Any) {
        if let button = sender as? UIBarButtonItem {
            if let title = button.title {
                switch title {
                case "Add image":
                    mapImage?.hidden = false;
                    mapImage?.position = map.mapCenter;
                    mapImage?.angle = Float(arc4random_uniform(360));

                    button.title = "Move image"
                case "Move image":
                    mapImage?.position = map.mapCenter

                    button.title = "Remove image"
                case "Remove image":
                    mapImage?.hidden = true

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
                    menu.setTargetRect(CGRect.init(origin: point, size: CGSize.init(width: 1, height: 1)), in: map)
                    menu.menuItems = [UIMenuItem.init(title: "Add pin", action: #selector(MapViewController.addPin))]
                    menu.setMenuVisible(true, animated: true)
                }
            }
        }

        map.tapGestureBlock = { [weak self] (point: CGPoint) in
            
            if let pins = self?.pins, let map = self?.map{
                if let pin = pins.findPin(point:point, mapView:map) {
                    let menu = UIMenuController.shared
                    if !menu.isMenuVisible{
                        let pinPos = map.makeDisplayPoint(from: pin.position)
                        self?.pinToDelete = pin
                        self?.becomeFirstResponder()
                        menu.setTargetRect(CGRect.init(origin: CGPoint.init(x: pinPos.x, y: pinPos.y-20.0), size: CGSize.init(width: 1, height: 1)), in: map)
                        menu.menuItems = [UIMenuItem.init(title: "Delete pin", action: #selector(MapViewController.deletePin))]
                        menu.setMenuVisible(true, animated: true)
                    }
                }
            }                        
        }
    }

    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    func addPin() {
        
        if pins == nil {
            pins = ImageGroup.init();
        }
        
        if mapImageGroup == nil {
            mapImageGroup = GLMapImageGroup.init(callback: pins!, andDrawOrder: 3);
            map.add(mapImageGroup!);
        }

        let pinPos = map.makeMapPoint(fromDisplay: menuPos!)
        let pin = Pin.init(position: pinPos, imageID: UInt32(pins!.count() % 3))
        pins?.append(pin)
        mapImageGroup?.setNeedsUpdate(false)
    }

    func deletePin() {
        if pinToDelete != nil {
            pins?.remove(pinToDelete!);
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
            if let image = GLMapVectorImageFactory.shared().image(fromSvgpb: imagePath, withScale: 0.2) {
                // Create style collection - it's storage for all images possible to use for markers
                let style = GLMapMarkerStyleCollection.init()
                style.addStyle(with: image)

                //If marker layer constructed using GLMapVectorObjectArray location of marker is automatically calculated as
                //[GLMapVectorObject point]. So you don't need to set markerLocationBlock.
                //style.setMarkerLocationBlock()

                // Data fill block used to set marker style and text
                // It could work with any user defined object type.
                // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
                style.setMarkerDataFill { (marker, data) in
                    data.setStyle(0)
                }

                // Load UK postal codes from GeoJSON
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType:"json") {
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        // Put our array of objects into marker layer. It could be any custom array of objects.
                        // Disable clustering in this demo
                        let markerLayer = GLMapMarkerLayer.init(vectorObjects: objects, andStyles: style, clusteringRadius:0, drawOrder: 2)
                        // Add marker layer on map
                        map.add(markerLayer)
                        let bbox = objects.bbox
                        map.setMapCenter(bbox.center, zoom: map.mapZoom(for: bbox))
                    }
                }

            }
        }
    }

    func markerLayerWithClustering() {
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svgpb") {
            // We use different colours for our clusters
            let tintColors = [
                GLMapColorMake(33, 0, 255, 255),
                GLMapColorMake(68, 195, 255, 255),
                GLMapColorMake(63, 237, 198, 255),
                GLMapColorMake(15, 228, 36, 255),
                GLMapColorMake(168, 238, 25, 255),
                GLMapColorMake(214, 234, 25, 255),
                GLMapColorMake(223, 180, 19, 255),
                GLMapColorMake(255, 0, 0, 255)
            ]

            // Create style collection - it's storage for all images possible to use for markers and clusters
            let styleCollection = GLMapMarkerStyleCollection.init()

            // Render possible images from svgpb
            var maxWidth = 0.0;
            for i in 0..<tintColors.count {
                let scale = 0.2 + 0.1 * Double(i)
                if let image = GLMapVectorImageFactory.shared().image(fromSvgpb: imagePath, withScale: scale, andTintColor: tintColors[i] ) {
                    if(maxWidth < (Double)(image.size.width)){
                        maxWidth = (Double)(image.size.width)
                    }
                    styleCollection.addStyle(with: image)
                }
            }

            // Create style for text
            let textStyle = GLMapVectorStyle.createStyle("{text-color:black;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}")

            //If marker layer constructed using GLMapVectorObjectArray location of marker is automatically calculated as
            //[GLMapVectorObject point]. So you don't need to set markerLocationBlock.
            //styleCollection.setMarkerLocationBlock()

            // Data fill block used to set marker style and text
            // It could work with any user defined object type.
            // Additional data for markers will be requested only for markers that are visible or not far from bounds of screen.
            styleCollection.setMarkerDataFill { (marker, data) in
                if let obj = marker as? GLMapVectorObject {
                    data.setStyle(0)
                    if let name = obj.value(forKey: "name") {
                        data.setText(name, offset: CGPoint.init(x: 0, y: 8), style: textStyle!)
                    }
                }
            }

            // Union fill block used to set style for cluster object. First param is number objects inside the cluster and second is marker object.
            styleCollection.setMarkerUnionFill({ (markerCount, data) in
                // we have 8 marker styles for 1, 2, 4, 8, 16, 32, 64, 128+ markers inside
                var markerStyle = Int( log2( Double(markerCount) ) )
                if markerStyle >= tintColors.count {
                    markerStyle = tintColors.count-1
                }
                data.setStyle( UInt(markerStyle) )
                data.setText("\(markerCount)", offset: CGPoint.zero, style: textStyle!)
            })

            // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on main thread only when data is loaded.
            DispatchQueue.global().async {
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType:"json") {
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        let markerLayer = GLMapMarkerLayer.init(vectorObjects: objects, andStyles: styleCollection, clusteringRadius:maxWidth/2, drawOrder:2)
                        let bbox = objects.bbox
                        
                        DispatchQueue.main.async { [weak self] in
                            if let wself = self {
                                let map = wself.map;
                                map.add(markerLayer)
                                map.setMapCenter(bbox.center, zoom: map.mapZoom(for: bbox))
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
                GLMapColorMake(33, 0, 255, 255),
                GLMapColorMake(68, 195, 255, 255),
                GLMapColorMake(63, 237, 198, 255),
                GLMapColorMake(15, 228, 36, 255),
                GLMapColorMake(168, 238, 25, 255),
                GLMapColorMake(214, 234, 25, 255),
                GLMapColorMake(223, 180, 19, 255),
                GLMapColorMake(255, 0, 0, 255)
            ]
            
            // Create style collection - it's storage for all images possible to use for markers and clusters
            let styleCollection = GLMapMarkerStyleCollection.init()
            
            // Render possible images from svgpb
            var maxWidth = 0.0
            for i in 0..<tintColors.count {
                let scale = 0.2 + 0.1 * Double(i)
                if let image = GLMapVectorImageFactory.shared().image(fromSvgpb: imagePath, withScale: scale, andTintColor: tintColors[i] ) {
                    if(maxWidth<(Double)(image.size.width)){
                        maxWidth = (Double)(image.size.width)
                    }
                    let styleIndex = styleCollection.addStyle(with: image)
                    styleCollection.setStyleName("uni\(styleIndex)", forStyleIndex: styleIndex)
                }
            }
            
            // When we have big dataset to load. We could load data and create marker layer in background thread. And then display marker layer on main thread only when data is loaded.
            DispatchQueue.global().async {
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType:"json") {
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
                            
                            let markerLayer = GLMapMarkerLayer.init(vectorObjects: objects, cascadeStyle: cascadeStyle, styleCollection: styleCollection, clusteringRadius:maxWidth/2, drawOrder:2)
                            let bbox = objects.bbox
                            DispatchQueue.main.async { [weak self] in
                                if let wself = self {
                                    let map = wself.map
                                    map.add(markerLayer)
                                    map.setMapCenter(bbox.center, zoom: map.mapZoom(for: bbox))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func multiLineDemo() {
        let multiline = GLMapVectorObject.init()

        let line1 = [GLMapGeoPoint.init(lat: 53.8869, lon: 27.7151), // Minsk
            GLMapGeoPoint.init(lat: 50.4339, lon: 30.5186), // Kiev
            GLMapGeoPoint.init(lat: 52.2251, lon: 21.0103), // Warsaw
            GLMapGeoPoint.init(lat: 52.5037, lon: 13.4102), // Berlin
            GLMapGeoPoint.init(lat: 48.8505, lon: 2.3343)]  // Paris

        multiline.addGeoLine(line1)

        let line2 = [GLMapGeoPoint.init(lat: 52.3690, lon: 4.9021), // Amsterdam
            GLMapGeoPoint.init(lat: 50.8263, lon: 4.3458), // Brussel
            GLMapGeoPoint.init(lat: 49.6072, lon: 6.1296)] // Luxembourg

        multiline.addGeoLine(line2)

        if let style = GLMapVectorCascadeStyle.createStyle("line{width: 2pt; color:green;}") {
            let drawable = GLMapDrawable.init()
            drawable.setVectorObject(multiline, for: map, with: style, completion: nil)
            map.add(drawable);
        }
    }

    func polygonDemo() {

        func fillPoints(centerPoint: GLMapGeoPoint, radius: Double) -> Array<GLMapGeoPoint> {
            let pointCount = 25
            let sectorSize = 2*Double.pi / Double(pointCount)

            var circlePoints: Array<GLMapGeoPoint> = []
            for i in 0..<pointCount {
                circlePoints.append(GLMapGeoPoint.init(lat: centerPoint.lat + cos(sectorSize * Double(i)) * radius,
                                                       lon: centerPoint.lon + sin(sectorSize * Double(i)) * radius))
            }
            return circlePoints
        }

        let polygon = GLMapVectorObject.init()
        let centerPoint = GLMapGeoPointMake(53, 27)

        polygon.addGeoPolygonOuterRing(fillPoints(centerPoint: centerPoint, radius: 10))

        polygon.addGeoPolygonInnerRing(fillPoints(centerPoint: centerPoint, radius: 5))

        if let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#10106050; width:4pt; color:green;}") {
            let drawable = GLMapDrawable.init()
            drawable.setVectorObject(polygon, for: map, with: style, completion: nil)
            map.add(drawable)
        }

        map.move(to: centerPoint)
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
                
                for i in 0..<objects.count {
                    let drawable = GLMapDrawable.init()
                    drawable.setVectorObject(objects[i], for: map, with: style, completion: nil);
                    if (i==0) {
                        flashObject(object: drawable)
                    }else {
                        map.add(drawable);
                    }
                }
            }
        }
    }

    var flashAdd: Bool = false
    func flashObject(object: GLMapDrawable) {
        if (flashAdd) {
            map.add(object)
        } else {
            map.remove(object)
        }
        flashAdd = !flashAdd
        self.perform(#selector(MapViewController.flashObject), with: object, afterDelay: 1)
    }

    func screenshotDemo() {
        NSLog("Start capturing frame")
        map.captureFrame { [weak self] (image: UIImage?) in
            if image != nil {
                NSLog("Image captured \(String(describing: image))")
                let alert = UIAlertController.init(title: nil, message: "Image captured \(String(describing: image))", preferredStyle:.alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler:nil))

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
                    
                    for i in 0..<objects.count {
                        let drawable = GLMapDrawable.init()
                        drawable.setVectorObject(objects[i], for: map, with: style, completion: nil)
                        map.add(drawable);
                    }
                }
        }

        let testView = UIView.init(frame: CGRect.init(x: 350, y: 200, width: 150, height: 200))
        testView.backgroundColor = UIColor.black

        let testView2 = UIView.init(frame: CGRect.init(x: 200, y: 200, width: 150, height: 200))
        testView2.backgroundColor = UIColor.white

        var y: CGFloat = 0.0

        for i in 0...6 {
            let font = UIFont.systemFont(ofSize: CGFloat.init(i * 5 + 5))
            let lbl = UILabel.init()
            lbl.text = "Test12"
            lbl.font = font
            lbl.textColor = UIColor.white
            lbl.sizeToFit()
            lbl.frame = CGRect.init(origin: CGPoint.init(x: 0, y: y), size: lbl.frame.size)
            testView.addSubview(lbl)

            let lbl2 = UILabel.init()
            lbl2.text = "Test12"
            lbl2.font = font
            lbl2.textColor = UIColor.black
            lbl2.sizeToFit()
            lbl2.frame = CGRect.init(origin: CGPoint.init(x: 0, y: y), size: lbl2.frame.size)
            testView2.addSubview(lbl2)

            y += lbl.frame.size.height
        }

        map.addSubview(testView)
        map.addSubview(testView2)
    }

    func flyToDemo() {
        let barButton = UIBarButtonItem.init(title: "Fly", style: .plain, target: self, action: #selector(MapViewController.flyTo))
        self.navigationItem.rightBarButtonItem = barButton

        GLMapManager.shared().tileDownloadingAllowed = true
        map.fly(to: GLMapGeoPoint.init(lat: 37.3257, lon: -122.0353), zoomLevel:14)
    }

    func flyTo() {
        let minPt = GLMapGeoPoint.init(lat: 33, lon: -118)
        let maxPt = GLMapGeoPoint.init(lat: 48, lon: -85)

        map.fly(to: GLMapGeoPoint.init(lat: minPt.lat + (maxPt.lat - minPt.lat) * drand48(),
                                       lon: minPt.lon + (maxPt.lon - minPt.lon) * drand48()),
                zoomLevel:14)
    }

    func styleReloadDemo() {
        let textField = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: self.navigationController!.navigationBar.frame.size.width, height: 21))
        textField.placeholder = "Enter style URL"
        self.navigationItem.titleView = textField

        textField.becomeFirstResponder()

        let barButton = UIBarButtonItem.init(title: "Reload style", style: .plain, target: self, action: #selector(MapViewController.styleReload))
        self.navigationItem.rightBarButtonItem = barButton
    }

    func styleReload() {
        let urlField = self.navigationItem.titleView as! UITextField

        do {
            let styleData = try Data.init(contentsOf: URL.init(string: urlField.text!)!)
            if map.loadStyle({ (name) -> GLMapResource in
                if (name == "Style.mapcss") {
                    return GLMapResourceWithData(styleData)
                }

                return GLMapResourceEmpty()
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
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
            var trackPoint = GLTrackPoint.init(pt: mapPoint, color: GLMapColorMake(255, 255, 0, 255))

            if trackData != nil {
                trackData = GLMapTrackData.init(data: trackData!, andNewPoint: trackPoint, startNewSegment: false)
            } else {
                trackData = GLMapTrackData.init(points: &trackPoint, count: 1)
            }
        }
        
        if track == nil {
            track = GLMapTrack.init(drawOrder: 2, andTrackData: trackData)
            track?.setStyle(GLMapVectorStyle.createStyle("{width:5pt;}"))
            map.add(track!)
        } else {
            track?.setTrackData(trackData!)
        }
        
    }
}
