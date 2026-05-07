import GLMap
import GLMapSwift
import GLSearch
import UIKit

class OfflineSearchDemo: DemoMapViewController {
    private var markerLayer: GLMapMarkerLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        map.mapGeoCenter = GLMapGeoPoint(lat: 42.4341, lon: 19.26)
        map.mapZoomLevel = 15

        let offlineMapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm")!
        GLMapManager.shared.add(.map, path: offlineMapPath, bbox: .empty)
        performSearch()
    }

    private func performSearch() {
        let center = GLMapGeoPoint(lat: 42.4341, lon: 19.26)

        let search = GLSearch()
        search.center = GLMapPoint(lat: center.lat, lon: center.lon)
        search.limit = 50
        search.setLocaleSettings(map.localeSettings)

        let categories = GLSearchCategories.shared.categoriesStarted(
            with: ["restaurant"],
            localeSettings: GLMapLocaleSettings(localesOrder: ["en"], unitSystem: .international)
        )
        guard !categories.isEmpty else {
            showAlert(message: "No restaurant category found")
            return
        }
        search.add(GLSearchFilter(category: categories[0]))

        search.searchAsync { [weak self] results in
            self?.displayResults(results)
        }
    }

    private func displayResults(_ results: GLMapVectorObjectArray) {
        guard let imagePath = svgPath("cluster"),
              let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: 0.2, andTintColor: GLMapColor(red: 0xFF, green: 0, blue: 0, alpha: 0xFF))
        else { return }

        let styles = GLMapMarkerStyleCollection()
        styles.addStyle(with: image)

        styles.setMarkerLocationBlock { marker -> GLMapPoint in
            (marker as? GLMapVectorObject)?.point ?? GLMapPoint()
        }

        styles.setMarkerDataFill { _, data in
            data.setStyle(0)
        }

        let layer = GLMapMarkerLayer(markers: results.array(), andStyles: styles, clusteringRadius: 0, drawOrder: 2)
        map.add(layer)
        markerLayer = layer

        if results.count > 0 {
            let bbox = results.bbox
            map.mapCenter = bbox.center
            map.mapScale = map.mapScale(for: bbox)
        }

        title = "Found \(results.count) restaurants"
    }
}
