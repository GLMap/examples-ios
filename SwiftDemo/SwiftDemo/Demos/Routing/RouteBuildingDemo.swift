import GLMap
import GLMapSwift
import GLRoute
import UIKit

class RouteBuildingDemo: DemoMapViewController {
    private var routingMode: UISegmentedControl!
    private var networkMode: UISegmentedControl!
    private var startPoint = GLMapGeoPoint(lat: 41.1457, lon: -8.6107) // Porto, São Bento
    private var endPoint = GLMapGeoPoint(lat: 41.1597, lon: -8.6300) // Porto, Casa da Música
    private var routeTrack: GLMapTrack?
    private var requestID: Int64 = 0
    private var routeGeneration = 0
    private var valhallaConfig: String?
    private let routeStyle = GLMapVectorStyle.createStyle("{width:7pt; fill-image:\"track-arrow.svg\";}")!

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        guard let configPath = Bundle.main.path(forResource: "valhalla", ofType: "json"),
              let config = try? String(contentsOfFile: configPath)
        else {
            showAlert(message: "valhalla.json not found")
            return
        }
        valhallaConfig = config

        routingMode = UISegmentedControl(items: ["Auto", "Bike", "Walk"])
        routingMode.selectedSegmentIndex = 0
        routingMode.addTarget(self, action: #selector(updateRoute), for: .valueChanged)

        networkMode = UISegmentedControl(items: ["Online", "Offline"])
        networkMode.selectedSegmentIndex = 0
        networkMode.addTarget(self, action: #selector(updateRoute), for: .valueChanged)

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: routingMode),
            UIBarButtonItem(customView: networkMode),
        ]
        navigationItem.prompt = "Tap map to set departure and destination"

        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(geoPoint: startPoint))
        bbox.add(point: GLMapPoint(geoPoint: endPoint))
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox) / 2

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let pt = gesture.location(in: map)
            let geoPt = GLMapGeoPoint(point: map.makeMapPoint(fromDisplay: pt))

            let alert = UIAlertController(title: "Set Point", message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Departure", style: .default) { _ in
                self.startPoint = geoPt
                self.updateRoute()
            })
            alert.addAction(UIAlertAction(title: "Destination", style: .default) { _ in
                self.endPoint = geoPt
                self.updateRoute()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.popoverPresentationController?.sourceView = map
            alert.popoverPresentationController?.sourceRect = CGRect(x: pt.x, y: pt.y, width: 1, height: 1)
            present(alert, animated: true)
        }

        updateRoute()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelRouteRequest()
    }

    @objc private func updateRoute() {
        guard let valhallaConfig else { return }
        cancelRouteRequest()
        let generation = routeGeneration

        let request = GLRouteRequest()
        switch routingMode.selectedSegmentIndex {
        case 0: request.setAutoWithOptions(.default)
        case 1: request.setBicycleWithOptions(.default)
        default: request.setPedestrianWithOptions(.default)
        }

        request.add(GLRoutePoint(pt: startPoint, heading: .nan, type: .break))
        request.add(GLRoutePoint(pt: endPoint, heading: .nan, type: .break))

        let completion: GLRouteRequestCompletionBlock = { [weak self] (result: GLRoute?, error: Error?) in
            guard let self, routeGeneration == generation else { return }
            requestID = 0
            if let result, let trackData = result.trackData(with: GLMapColor(red: 50, green: 200, blue: 0, alpha: 200)) {
                if routeTrack == nil {
                    let track = GLMapTrack(drawOrder: 5)
                    map.add(track)
                    routeTrack = track
                }
                routeTrack?.setData(trackData, style: routeStyle)
            }
            if let error {
                showAlert("Routing Error", message: error.localizedDescription)
            }
        }

        if networkMode.selectedSegmentIndex != 0 {
            requestID = request.startOffline(withConfig: valhallaConfig, completion: completion)
        } else {
            requestID = request.startOnline(completion: completion)
        }
    }

    private func cancelRouteRequest() {
        routeGeneration += 1
        if requestID != 0 { GLRouteRequest.cancel(requestID) }
        requestID = 0
    }
}
