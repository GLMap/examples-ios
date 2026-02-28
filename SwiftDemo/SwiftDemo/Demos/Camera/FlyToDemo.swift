import GLMap
import GLMapSwift
import UIKit

class FlyToDemo: DemoMapViewController {
    private let destinations: [(name: String, point: GLMapGeoPoint)] = [
        ("Rome", GLMapGeoPoint(lat: 41.8933, lon: 12.4829)),
        ("Paris", GLMapGeoPoint(lat: 48.8566, lon: 2.3522)),
        ("London", GLMapGeoPoint(lat: 51.5072, lon: -0.1275)),
        ("Istanbul", GLMapGeoPoint(lat: 41.0082, lon: 28.9784)),
        ("Barcelona", GLMapGeoPoint(lat: 41.3874, lon: 2.1686)),
        ("Amsterdam", GLMapGeoPoint(lat: 52.3690, lon: 4.9021)),
    ]
    private var destIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Fly", style: .plain, target: self, action: #selector(flyToNext)
        )

        let start = destinations[0]
        title = start.name
        map.animate { animation in
            animation.flyToMode = .enabled
            self.map.mapZoomLevel = 14
            self.map.mapGeoCenter = start.point
        }
    }

    @objc private func flyToNext() {
        destIndex = (destIndex + 1) % destinations.count
        let dest = destinations[destIndex]
        title = dest.name

        map.animate { animation in
            animation.flyToMode = .enabled
            self.map.mapZoomLevel = 14
            self.map.mapGeoCenter = dest.point
        }
    }
}
