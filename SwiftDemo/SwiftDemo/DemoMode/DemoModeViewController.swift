import GLMap
import GLMapSwift
import GLRoute
import GLSearch
import UIKit

class DemoModeViewController: UIViewController {
    private(set) var map: GLMapView!
    let overlay = DemoOverlayView()

    private var stylePath: String = ""
    private var sceneIndex = 0
    private var isRunning = false
    private var overlayLayers: [AnyObject] = []
    private var contentGeneration = 0
    private var routeRequestID: Int64 = 0
    private var searchRequestID: Int64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        if let path = GLMapManager.shared.resourcesBundle.path(forResource: "DefaultStyle", ofType: "bundle") {
            stylePath = path
        }

        // Map view
        map = GLMapView(frame: view.bounds)
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(map)

        GLMapManager.shared.tileDownloadingAllowed = true
        loadLightStyle()

        // Overlay
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)

        overlay.exitButton.addTarget(self, action: #selector(exitDemoMode), for: .touchUpInside)

        // Tap anywhere to exit
        let tap = UITapGestureRecognizer(target: self, action: #selector(exitDemoMode))
        tap.cancelsTouchesInView = false
        overlay.addGestureRecognizer(tap)

        // Disable idle timer
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startDemoLoop()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isRunning = false
        clearOverlays()
        UIApplication.shared.isIdleTimerDisabled = false
        GLMapManager.shared.tileDownloadingAllowed = false
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    // MARK: - Demo loop

    private func startDemoLoop() {
        sceneIndex = 0
        isRunning = true
        runNextScene()
    }

    private func runNextScene() {
        guard isRunning else { return }

        if sceneIndex >= DemoScenes.all.count {
            sceneIndex = 0 // Loop
            clearOverlays()
            overlay.hideTitle()
        }

        let scene = DemoScenes.all[sceneIndex]
        sceneIndex += 1

        overlay.showCaption(scene.caption)

        scene.action(self) { [weak self] in
            self?.runNextScene()
        }
    }

    @objc private func exitDemoMode() {
        isRunning = false
        dismiss(animated: true)
    }

    // MARK: - Style helpers

    func loadLightStyle() {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        parser.setOptions([:], defaultValue: true)
        if let style = try? parser.parseFromResources() {
            map.setStyle(style)
            map.reloadTiles()
        }
    }

    func loadDarkStyle() {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        parser.setOptions(["Theme": "Dark"], defaultValue: true)
        if let style = try? parser.parseFromResources() {
            map.setStyle(style)
            map.reloadTiles()
        }
    }

    // MARK: - Overlay helpers

    func clearOverlays() {
        contentGeneration += 1
        if routeRequestID != 0 {
            GLRouteRequest.cancel(routeRequestID)
            routeRequestID = 0
        }
        if searchRequestID != 0 {
            GLSearchRequest.cancel(searchRequestID)
            searchRequestID = 0
        }
        for layer in overlayLayers {
            if let drawable = layer as? GLMapDrawable {
                map.remove(drawable)
            } else if let markerLayer = layer as? GLMapMarkerLayer {
                map.remove(markerLayer)
            } else if let track = layer as? GLMapTrack {
                map.remove(track)
            }
        }
        overlayLayers.removeAll()
    }

    func showMarkerClusters() {
        let generation = contentGeneration
        guard let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg") else { return }

        let tintColors = [
            GLMapColor(red: 33, green: 0, blue: 255, alpha: 255),
            GLMapColor(red: 68, green: 195, blue: 255, alpha: 255),
            GLMapColor(red: 63, green: 237, blue: 198, alpha: 255),
            GLMapColor(red: 15, green: 228, blue: 36, alpha: 255),
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

        styleCollection.setMarkerDataFill { _, data in
            data.setStyle(0)
        }
        styleCollection.setMarkerUnionFill { count, data in
            let idx = min(Int(log2(Double(count))), tintColors.count - 1)
            data.setStyle(UInt32(idx))
            data.setText("\(count)", offset: .zero, style: textStyle)
        }

        DispatchQueue.global().async { [weak self] in
            guard let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json"),
                  let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath) else { return }

            let markerLayer = GLMapMarkerLayer(
                vectorObjects: objects,
                andStyles: styleCollection,
                clusteringRadius: maxWidth / 2,
                drawOrder: 2
            )
            let bbox = objects.bbox

            DispatchQueue.main.async { [weak self] in
                guard let self, isRunning, generation == contentGeneration else { return }
                self.map.add(markerLayer)
                self.overlayLayers.append(markerLayer)
                self.map.mapCenter = bbox.center
                self.map.mapScale = self.map.mapScale(for: bbox)
            }
        }
    }

    func buildDemoRoute(from start: GLMapGeoPoint, to end: GLMapGeoPoint) {
        let generation = contentGeneration
        let request = GLRouteRequest()
        var options = CostingOptionsAuto.default
        options.road.useHighways = 0 // Keep this showcase route on the scenic coastal roads.
        request.setAutoWithOptions(options)
        request.add(GLRoutePoint(pt: start, heading: .nan, type: .break))
        request.add(GLRoutePoint(pt: end, heading: .nan, type: .break))

        let routeStyle = GLMapVectorStyle.createStyle("{width: 7pt; fill-image:\"track-arrow.svg\";}")!

        routeRequestID = request.startOnline { [weak self] route, _ in
            guard let self, isRunning, generation == contentGeneration else { return }
            routeRequestID = 0
            guard let route,
                  let trackData = route.trackData(with: GLMapColor(red: 50, green: 200, blue: 0, alpha: 200)) else { return }

            let track = GLMapTrack(drawOrder: 5)
            track.setData(trackData, style: routeStyle)
            map.add(track)
            overlayLayers.append(track)
        }
    }

    func showOnlineSearchResults(at center: GLMapGeoPoint) {
        let generation = contentGeneration
        let request = GLSearchRequest(
            type: .search,
            text: "",
            center: center,
            limit: 30,
            locales: ["en", "native"],
            categories: ["restaurant"]
        )

        searchRequestID = request.startOnline { [weak self] results, error in
            guard let self, isRunning, generation == contentGeneration else { return }
            searchRequestID = 0
            guard error == nil, let results, results.count > 0 else {
                overlay.showCaption("Search unavailable")
                return
            }
            guard let imagePath = Bundle.main.path(forResource: "cluster", ofType: "svg"),
                  let image = GLMapVectorImageFactory.shared.image(
                      fromSvg: imagePath,
                      withScale: 0.2,
                      andTintColor: GLMapColor(red: 0, green: 102, blue: 204, alpha: 255)
                  )
            else { return }

            let styles = GLMapMarkerStyleCollection()
            styles.addStyle(with: image)
            styles.setMarkerDataFill { _, data in data.setStyle(0) }

            let markerLayer = GLMapMarkerLayer(
                vectorObjects: results,
                andStyles: styles,
                clusteringRadius: 0,
                drawOrder: 3
            )
            map.add(markerLayer)
            overlayLayers.append(markerLayer)
            overlay.showCaption("Search · \(results.count) results")

            let bbox = results.bbox
            map.animate { animation in
                animation.duration = 1.5
                self.map.mapCenter = bbox.center
                self.map.mapScale = self.map.mapScale(for: bbox)
            }
        }
    }
}
