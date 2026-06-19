import GLMap
import GLMapSwift
import GLSearch
import UIKit

// One `GLSearchRequest`, two transports. `startOnline` searches the server's
// global data; `startOffline` searches downloaded maps. The request, the ranking,
// and the result display are identical — only the candidate set differs. Tap
// Online / Offline to run the same query both ways and compare the results.
class SearchDemo: DemoMapViewController {
    private var markerLayer: GLMapMarkerLayer?
    private var requestID: Int64 = 0

    // Podgorica — inside the bundled Montenegro offline map, so `startOffline` has data.
    private let center = GLMapGeoPoint(lat: 42.4341, lon: 19.26)

    override func viewDidLoad() {
        super.viewDidLoad()

        GLMapManager.shared.tileDownloadingAllowed = true
        // Load an offline map so the offline path has something to search.
        if let offlineMapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.add(.map, path: offlineMapPath, bbox: .empty)
        }

        map.mapGeoCenter = center
        map.mapZoomLevel = 12
        title = "Search"

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Online", style: .plain, target: self, action: #selector(runOnline)),
            UIBarButtonItem(title: "Offline", style: .plain, target: self, action: #selector(runOffline)),
        ]

        runOnline()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelRunningRequest()
    }

    // The single request model shared by both transports.
    private func makeRequest() -> GLSearchRequest {
        GLSearchRequest(
            type: .search,
            text: "",
            locales: ["en", "native"],
            limit: 50,
            center: center,
            categories: ["restaurant"]
        )
    }

    @objc private func runOnline() {
        cancelRunningRequest()
        title = "Online: searching…"
        requestID = makeRequest().startOnline { [weak self] results, error in
            self?.handle(results, error, source: "Online",
                         color: GLMapColor(red: 0x00, green: 0x66, blue: 0xCC, alpha: 0xFF))
        }
        warnIfNotStarted()
    }

    @objc private func runOffline() {
        cancelRunningRequest()
        title = "Offline: searching…"
        requestID = makeRequest().startOffline { [weak self] results, error in
            self?.handle(results, error, source: "Offline",
                         color: GLMapColor(red: 0xFF, green: 0x00, blue: 0x00, alpha: 0xFF))
        }
        warnIfNotStarted()
    }

    private func handle(_ results: GLMapVectorObjectArray?, _ error: Error?, source: String, color: GLMapColor) {
        requestID = 0
        if let error {
            title = source
            showAlert("\(source) Search Failed", message: error.localizedDescription)
            return
        }
        guard let results else {
            title = "\(source): no results"
            return
        }
        displayResults(results, source: source, color: color)
    }

    private func warnIfNotStarted() {
        if requestID == 0 {
            showAlert(message: "Search request was not started.")
        }
    }

    private func cancelRunningRequest() {
        guard requestID != 0 else { return }
        GLSearchRequest.cancel(requestID)
        requestID = 0
    }

    private func displayResults(_ results: GLMapVectorObjectArray, source: String, color: GLMapColor) {
        if let markerLayer {
            map.remove(markerLayer)
        }
        markerLayer = nil

        guard let imagePath = svgPath("cluster"),
              let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: 0.2, andTintColor: color)
        else { return }

        let styles = GLMapMarkerStyleCollection()
        styles.addStyle(with: image)
        styles.setMarkerLocationBlock { marker -> GLMapPoint in
            (marker as? GLMapVectorObject)?.point ?? GLMapPoint()
        }
        styles.setMarkerDataFill { _, data in
            data.setStyle(0)
        }

        let layer = GLMapMarkerLayer(markers: results.array(), andStyles: styles, clusteringRadius: 0, drawOrder: 3)
        map.add(layer)
        markerLayer = layer

        if results.count > 0 {
            let bbox = results.bbox
            map.mapCenter = bbox.center
            map.mapScale = map.mapScale(for: bbox)
        }

        title = "\(source): \(results.count) restaurants"
    }
}
