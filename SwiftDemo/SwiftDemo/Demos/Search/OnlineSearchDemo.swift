import GLMap
import GLMapSwift
import GLSearch
import UIKit

class OnlineSearchDemo: DemoMapViewController {
    private enum RequestMode {
        case search
        case autocomplete
    }

    private var markerLayer: GLMapMarkerLayer?
    private var requestID: Int64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 53.9025, lon: 27.5618)
        map.mapZoomLevel = 13
        title = "Online Search"

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Search", style: .plain, target: self, action: #selector(runSearch)),
            UIBarButtonItem(title: "Autocomplete", style: .plain, target: self, action: #selector(runAutocomplete)),
        ]

        start(.search)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelRunningRequest()
    }

    @objc private func runSearch() {
        start(.search)
    }

    @objc private func runAutocomplete() {
        start(.autocomplete)
    }

    private func start(_ mode: RequestMode) {
        cancelRunningRequest()

        let center = GLMapGeoPoint(lat: 53.9025, lon: 27.5618)
        let request: GLSearchRequest
        switch mode {
        case .search:
            title = "Searching cafes..."
            request = GLSearchRequest(
                type: .search,
                text: "coffee",
                language: "en",
                fallbackLanguages: ["native"],
                limit: 20,
                center: center,
                categories: ["cafe"]
            )

        case .autocomplete:
            title = "Loading suggestions..."
            request = GLSearchRequest(
                type: .autocomplete,
                text: "Mins",
                language: "en",
                fallbackLanguages: ["native"],
                limit: 5,
                center: center,
                categories: ["city"]
            )
        }

        requestID = request.startOnline { [weak self] results, error in
            guard let self else { return }
            requestID = 0

            if let error {
                title = "Online Search"
                showAlert("Search Failed", message: error.localizedDescription)
                return
            }

            guard let results else {
                title = "No Results"
                return
            }

            displayResults(results, mode: mode)
        }

        if requestID == 0 {
            title = "Online Search"
            showAlert(message: "Online search request was not started.")
        }
    }

    private func cancelRunningRequest() {
        guard requestID != 0 else { return }
        GLSearchRequest.cancel(requestID)
        requestID = 0
    }

    private func displayResults(_ results: GLMapVectorObjectArray, mode: RequestMode) {
        if let markerLayer {
            map.remove(markerLayer)
        }
        markerLayer = nil

        guard let imagePath = svgPath("cluster"),
              let image = GLMapVectorImageFactory.shared.image(
                  fromSvg: imagePath,
                  withScale: 0.2,
                  andTintColor: GLMapColor(red: 0x00, green: 0x66, blue: 0xCC, alpha: 0xFF)
              )
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

        switch mode {
        case .search:
            title = "Found \(results.count) cafes"
        case .autocomplete:
            title = "Found \(results.count) suggestions"
        }
    }
}
