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

class MapViewController: UIViewController {
    let map = GLMapView()
    let downloadButton = UIButton(type:.system)
    let locationManager = CLLocationManager.init()

    typealias Demo = ViewController.Demo
    
    var currentDemo:Demo = .OfflineMap
    
    let demoCases = [
        Demo.OfflineMap: showOfflineMap,
        Demo.EmbeddMap: showEmbedMap,
        Demo.OnlineMap: showOnlineMap,
        Demo.RasterOnlineMap: showRasterOnlineMap,
        Demo.ZoomToBBox: zoomToBBox,
        Demo.Notifications: testNotifications,
        Demo.SingleImage: singleImageDemo,
        Demo.MultiImage: multiImageDemo,
        Demo.MarkerLayer: markerLayer,
        Demo.MarkerLayerWithClustering: markerLayerWithClustering,
        Demo.MultiLine: multiLineDemo,
        Demo.Polygon: polygonDemo,
        Demo.GeoJSON: geoJsonDemo,
        Demo.Screenshot: screenshotDemo,
        Demo.Fonts: fontsDemo,
        Demo.FlyTo: flyToDemo
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
    
    func updateDownloadButton() -> Void {
        switch map.centerTileState {
        case GLMapTileState_HasData:
            if downloadButton.isHidden == false {
                downloadButton.isHidden = true
            }
        case GLMapTileState_NoData:
            if downloadButton.isHidden {
                downloadButton.isHidden = false
            }
            break
        default:
            break
        }
    }
    
    var mapToDownload:GLMapInfo? = nil
    
    func updateDownloadButtonText() -> Void {
        if map.centerTileState == GLMapTileState_NoData {
            let mapCenter = map.mapCenter()
        
            mapToDownload = GLMapManager.shared().map(at: mapCenter)
            
            if let map = mapToDownload {
                if map.state == .downloaded || map.distance(fromBorder: mapCenter) > 0.0 {
                    mapToDownload = nil
                }
            }
            
            if let map = mapToDownload {
                let downloadTask = GLMapManager.shared().downloadTask(forMap: map)
                
                let title:String
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
    
    func downloadButtonTap() -> Void {
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
    func showOfflineMap() -> Void {
        // nonthing to do
    }
    
    func showEmbedMap() -> Void {
        if let mapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared().addMap(withPath: mapPath)
        
            map.move(to: GLMapGeoPoint.init(lat: 42.4341, lon: 19.26), zoomLevel: 14)
        }
    }
    
    func showOnlineMap() -> Void {
        GLMapManager.shared().tileDownloadingAllowed = true
        
        map.move(to: GLMapGeoPoint.init(lat: 37.3257, lon: -122.0353), zoomLevel: 14)
    }
    
    func showRasterOnlineMap() -> Void {
        if let osmTileSource = OSMTileSource(cachePath:"/osm.sqlite") {
            map.setRasterSources([osmTileSource])
        }
    }
    
    func zoomToBBox() -> Void {
        // get pixel coordinates of geo points
        let geoPoint1 = GLMapGeoPoint.init(lat:52.5037, lon:13.4102);
        let geoPoint2 = GLMapGeoPoint.init(lat:53.9024, lon:27.5618);
        
        // get internal coordinates of geo points
        let mapPoint1 = GLMapView.makeMapPoint(from: geoPoint1)
        let mapPoint2 = GLMapView.makeMapPoint(from: geoPoint2)
        
        // get pixel positions of geo points
        let screenPoint1 = map.makeDisplayPoint(from: mapPoint1)
        let screenPoint2 = map.makeDisplayPoint(from: mapPoint2)
        
        // get scale between current screen size and desired screen size to fit points
        let wscale = fabs(screenPoint1.x - screenPoint2.x) / map.bounds.size.width;
        let hscale = fabs(screenPoint1.y - screenPoint2.y) / map.bounds.size.height;
        let zoomChange = fmax(wscale, hscale);
        
        // get new map center and zoom
        let newMapCenter = GLMapPoint.init(x: (mapPoint1.x + mapPoint2.x)/2,
                                           y: (mapPoint1.y + mapPoint2.y)/2)
        let newZoom = map.mapZoom() / Double(zoomChange)
        
        // set center point and change zoom to make screenDistance less or equal mapView.bounds
        map.setMapCenter(newMapCenter, zoom: newZoom);
    }
    
    func testNotifications() -> Void {
        // called every frame
        map.bboxChangedBlock = { (bbox: GLMapBBox) in
            print("bboxChanged \(bbox)")
        }
        
        // called only after movement
        map.mapDidMoveBlock = { (bbox: GLMapBBox) in
            print("mapDidMove \(bbox)")
        }
    }
    
    var mapImage: GLMapImage?
    
    func singleImageDemo() -> Void {
        if let image = UIImage.init(named: "pin1.png", in: nil, compatibleWith: nil) {
            mapImage = map.display(image)
            mapImage?.hidden = true
        }
        
        if mapImage == nil {
            return
        }
        
        // we'll just add button for this demo
        let barButton = UIBarButtonItem.init(title: "Add image", style: .plain, target: self, action: #selector(MapViewController.addImageButtonTap))
        
        self.navigationItem.rightBarButtonItem = barButton
        
        addImageButtonTap(barButton)
    }
    
    func addImageButtonTap(_ sender: Any) -> Void {
        if let button = sender as? UIBarButtonItem {
            if let title = button.title {
                switch title {
                case "Add image":
                    mapImage?.hidden = false
                    mapImage?.position = map.mapCenter()
                    mapImage?.angle = Float(arc4random_uniform(360))
                    
                    button.title = "Move image"
                case "Move image":
                    mapImage?.position = map.mapCenter()
                    
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
    
    struct Pin {
        let position:GLMapPoint
        let imageID:Int
        init(position: GLMapPoint, imageID: Int) {
            self.position = position
            self.imageID = imageID
        }
        static func == (lhs: Pin, rhs: Pin) -> Bool {
            return lhs.position == rhs.position && lhs.imageID == rhs.imageID
        }
    }
    
    var pins:Array<Pin> = []
    var mapImageGroup : GLMapImageGroup?
    var mapImageIDs : Array<NSNumber> = []
    var pinToDelete : Pin?
    
    func multiImageDemo() -> Void {
        let alert = UIAlertController.init(title: nil, message: "Long tap on map to add pin, tap on pin to remove it", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
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
            var rect = CGRect.init(x: -20, y: -20, width: 40, height: 40)
            rect = rect.offsetBy(dx:point.x , dy: point.y)
            
            if let pins = self?.pins, let map = self?.map {
                for pin in pins {
                    let pinPos = map.makeDisplayPoint(from: pin.position)
                    
                    if rect.contains(pinPos) {
                        let menu = UIMenuController.shared
                        if !menu.isMenuVisible {
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
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    func addPin() -> Void {
        if mapImageGroup == nil {
            if let imageGroup = map.createImageGroup() {
                
                let images = [UIImage.init(named: "pin1.png"),
                              UIImage.init(named: "pin2.png"),
                              UIImage.init(named: "pin3.png")]
                
                
                mapImageIDs = imageGroup.setImages(images as! [UIImage], completion: { [weak self] in
                    if let mapImageGroup = self?.mapImageGroup, let mapImageIDs = self?.mapImageIDs {
                        for i in 0 ... images.count - 1 {
                            if let image = images[i] {
                                mapImageGroup.setImageOffset(CGPoint.init(x: image.size.width/2, y: 0), forImageWithID: mapImageIDs[i].int32Value)
                            }
                        }
                    }
                })
                
                imageGroup.setObjectFill({ [weak self] (index: Int) -> GLMapImageGroupImageInfo in
                    if let pins = self?.pins {
                        if pins.count > 0 {
                            let pin = pins[index]
                            return GLMapImageGroupImageInfo.init(imageID: Int32(pin.imageID), pos: pin.position)
                        }
                    }
                    
                    return GLMapImageGroupImageInfo()
                })
                
                mapImageGroup = imageGroup
            }
        }
        
        let pinPos = map.makeMapPoint(fromDisplay: menuPos!)
        let pin = Pin.init(position: pinPos, imageID: mapImageIDs[pins.count % mapImageIDs.count].intValue)
        pins.append(pin)
        
        mapImageGroup?.setObjectCount(pins.count)
        mapImageGroup?.setNeedsUpdate()
    }
    
    func deletePin() -> Void {
        if pinToDelete != nil {
            if let indexToDelete = pins.index(where: { (pin : MapViewController.Pin) -> Bool in
                return pinToDelete! == pin
            }) {
                pins.remove(at: indexToDelete)
                
                mapImageGroup?.setObjectCount(pins.count)
                mapImageGroup?.setNeedsUpdate()
            }
        }
        
        if mapImageGroup != nil && pins.count == 0 {
            map.remove(mapImageGroup!)
            mapImageGroup = nil
        }
    }
    
    func markerLayer() -> Void {
        // Move map to the UK
        map.move(to: GLMapGeoPoint.init(lat: 53.46, lon: -2), zoomLevel: 6)
        
        // Create marker image
        if let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svgpb") {
            if let image = GLMapVectorImageFactory.shared().image(fromSvgpb: imagePath, withScale: 0.2) {
                // Create style collection - it's storage for all images possible to use for markers
                let style = GLMapMarkerStyleCollection.init()
                style.addMarkerImage(image)
                
                // Data fill block used to set location for marker and it's style
                // It could work with any user defined object type. GLMapVectorObject in our case.
                style.setMarkerDataFill({ (marker, data) in
                    if let obj = marker as? GLMapVectorObject  {
                        data.setLocation(obj.point)
                        data.setStyle(0)
                    }
                })
                
                // Load UK postal codes from GeoJSON
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType:"json") {
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        // Put our array of objects into marker layer. It could be any custom array of objects.
                        let markerLayer = GLMapMarkerLayer.init(markers: objects, andStyles: style)
                        // Disable clustering in this demo
                        markerLayer.clusteringEnabled = false
                        
                        // Add marker layer on map
                        map.display(markerLayer, completion: nil)
                    }
                }
                
            }
        }
    }
    
    func markerLayerWithClustering() -> Void {
        // Move map to the UK
        map.move(to: GLMapGeoPoint.init(lat: 53.46, lon: -2), zoomLevel: 6)
        
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
            let style = GLMapMarkerStyleCollection.init()
            
            // Render possible images from svgpb
            for i in 0 ... tintColors.count-1 {
                let scale = 0.2 + 0.1 * Double(i)
                if let image = GLMapVectorImageFactory.shared().image(fromSvgpb: imagePath, withScale: scale, andTintColor: tintColors[i] ) {
                    
                    style.addMarkerImage(image)
                }
            }
        
            // Create style for text
            let textStyle = GLMapVectorStyle.createStyle("{text-color:black;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}")
            
            // Data fill block used to set location for marker and it's style
            // It could work with any user defined object type. GLMapVectorObject in our case.
            style.setMarkerDataFill({ (marker, data) in
                if let obj = marker as? GLMapVectorObject  {
                    data.setLocation(obj.point)
                    data.setStyle(0)
                    
                    if let name = obj.value(forKey: "name") {
                        data.setText(name, offset: CGPoint.init(x: 0, y: 8), style: textStyle!)
                    }
                }
            })
            
            // Union fill block used to set style for cluster object. First param is number objects inside the cluster and second is marker object.
            style.setMarkerUnionFill({ (markerCount, data) in
                // we have 8 marker styles for 1, 2, 4, 8, 16, 32, 64, 128+ markers inside
                var markerStyle = Int( log2( Double(markerCount) ) )
                if markerStyle >= tintColors.count {
                    markerStyle = tintColors.count-1
                }
                
                data.setStyle( UInt(markerStyle) )
            })
            
            // When we have big dataset to load. We could load it in background thread. And create marker layer on main thread only when data is loaded.
            DispatchQueue.global().async {
                if let dataPath = Bundle.main.path(forResource: "cluster_data", ofType:"json") {
                    if let objects = GLMapVectorObject.createVectorObjects(fromFile: dataPath) {
                        DispatchQueue.main.async { [weak self] in
                            let markerLayer = GLMapMarkerLayer.init(markers: objects, andStyles: style)
                            //markerLayer.clusteringEnabled = false
                            
                            self?.map.display(markerLayer, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func multiLineDemo() -> Void {
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
        
        if let style = GLMapVectorStyle.createStyle("{galileo-fast-draw:true;width: 2pt;color:green;}") {
            map.add([multiline], with: style)
        }
    }
    
    func polygonDemo() -> Void {
        let pointCount = 25
        var circlePoints:Array<GLMapGeoPoint> = []
        let centerPoint = GLMapGeoPoint.init(lat:53, lon: 27)
        var radius = 10.0
        let sectorSize = 2*M_PI / Double(pointCount)
        
        for i in 0...pointCount-1 {
            circlePoints.append(GLMapGeoPoint.init(lat: centerPoint.lat + cos(sectorSize * Double(i)) * radius,
                                                   lon: centerPoint.lon + sin(sectorSize * Double(i)) * radius))
        }
        
        let polygon = GLMapVectorObject.init()
        
        polygon.addGeoPolygonOuterRing(circlePoints)
        
        radius = 5.0
        circlePoints.removeAll()
        for i in 0...pointCount-1 {
            circlePoints.append(GLMapGeoPoint.init(lat: centerPoint.lat + cos(sectorSize * Double(i)) * radius,
                                                   lon: centerPoint.lon + sin(sectorSize * Double(i)) * radius))
        }
        
        polygon.addGeoPolygonInnerRing(circlePoints)
        
        if let style = GLMapVectorStyle.createStyle("{fill-color:#10106050;}") {
            map.add([polygon], with: style)
        }
        
        map.move(to: centerPoint)
    }
  
    func geoJsonDemo() -> Void {
        if let objects = GLMapVectorObject.createVectorObjects(fromGeoJSON: "[{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [30.5186, 50.4339]}, \"properties\": {\"id\": \"1\", \"text\": \"test1\"}}," +
        "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [27.7151, 53.8869]}, \"properties\": {\"id\": \"2\", \"text\": \"test2\"}}," +
        "{\"type\":\"LineString\",\"coordinates\": [ [27.7151, 53.8869], [30.5186, 50.4339], [21.0103, 52.2251], [13.4102, 52.5037], [2.3343, 48.8505]]}," +
            "{\"type\":\"Polygon\",\"coordinates\":[[ [0.0, 10.0], [10.0, 10.0], [10.0, 20.0], [0.0, 20.0] ],[ [2.0, 12.0], [ 8.0, 12.0], [ 8.0, 18.0], [2.0, 18.0] ]]}]") {
        
            if let style = GLMapVectorStyle.createCascadeStyle("node[id=1]{icon-image:\"bus.svgpb\";icon-scale:0.5;icon-tint:green;text:eval(tag('text'));text-color:red;font-size:12;text-priority:100;}" +
                "node|z-9[id=2]{icon-image:\"bus.svgpb\";icon-scale:0.7;icon-tint:blue;;text:eval(tag('text'));text-color:red;font-size:12;text-priority:100;}" +
                "line{linecap: round; width: 5pt; color:blue; layer:100;}" +
                "area{fill-color:green; width:1pt; color:red; layer:100;}") {
                
                map.add(objects, with: style)
                
                flashObject(object: objects[0])
            }
        }
    }
    
    var flashAdd:Bool = false
    
    func flashObject(object: GLMapVectorObject) -> Void {
        if (flashAdd) {
            map.add(object, with: nil, onReadyToDraw: nil)
        } else {
            map.remove(object)
        }
        flashAdd = !flashAdd
        
        map.setNeedsDisplay()
        self.perform(#selector(MapViewController.flashObject), with: object, afterDelay: 1)
    }
    
    func screenshotDemo() -> Void {
        NSLog("Start capturing frame")
        map.captureFrame { [weak self] (image: UIImage?) in
            if image != nil {
                NSLog("Image captured \(image)")
                let alert = UIAlertController.init(title: nil, message: "Image captured \(image)", preferredStyle:.alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler:nil))
                
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func fontsDemo() -> Void {
        if let objects = GLMapVectorObject.createVectorObjects(fromGeoJSON:
            "[{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 64]}, \"properties\": {\"id\": \"1\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 63.6]}, \"properties\": {\"id\": \"2\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 62.3]}, \"properties\": {\"id\": \"3\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 61]}, \"properties\": {\"id\": \"4\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 60]}, \"properties\": {\"id\": \"5\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 58]}, \"properties\": {\"id\": \"6\"}}," +
            "{\"type\": \"Feature\", \"geometry\": {\"type\": \"Point\", \"coordinates\": [-25, 56]}, \"properties\": {\"id\": \"7\"}}," +
            "{\"type\":\"Polygon\",\"coordinates\":[[ [-30, 50], [-30, 80], [-10, 80], [-10, 50] ]]}]") {
        
        if let style = GLMapVectorStyle.createCascadeStyle(
            "node[id=1]{text:'Test12';text-color:black;font-size:5;text-priority:100;}" +
            "node[id=2]{text:'Test12';text-color:black;font-size:10;text-priority:100;}" +
            "node[id=3]{text:'Test12';text-color:black;font-size:15;text-priority:100;}" +
            "node[id=4]{text:'Test12';text-color:black;font-size:20;text-priority:100;}" +
            "node[id=5]{text:'Test12';text-color:black;font-size:25;text-priority:100;}" +
            "node[id=6]{text:'Test12';text-color:black;font-size:30;text-priority:100;}" +
            "node[id=7]{text:'Test12';text-color:black;font-size:35;text-priority:100;}" +
            "area{fill-color:white; layer:100;}") {
                map.add(objects, with: style)
            }
        }
        
        let testView = UIView.init(frame: CGRect.init(x: 350, y: 200, width: 150, height: 200))
        testView.backgroundColor = UIColor.black
        
        let testView2 = UIView.init(frame: CGRect.init(x: 200, y: 200, width: 150, height: 200))
        testView2.backgroundColor = UIColor.white
        
        var y:CGFloat = 0.0
        
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
    
    func flyToDemo() -> Void {
        let barButton = UIBarButtonItem.init(title: "Fly", style: .plain, target: self, action: #selector(MapViewController.flyTo))
        self.navigationItem.rightBarButtonItem = barButton
        
        GLMapManager.shared().tileDownloadingAllowed = true
        map.fly(to: GLMapGeoPoint.init(lat: 37.3257, lon: -122.0353), zoomLevel:14)
    }
    
    func flyTo() -> Void {
        let minPt = GLMapGeoPoint.init(lat: 33, lon: -118)
        let maxPt = GLMapGeoPoint.init(lat: 48, lon: -85)
        
        map.fly(to: GLMapGeoPoint.init(lat: minPt.lat + (maxPt.lat - minPt.lat) * drand48(),
                                       lon: minPt.lon + (maxPt.lon - minPt.lon) * drand48()),
                zoomLevel:14)
    }
}
