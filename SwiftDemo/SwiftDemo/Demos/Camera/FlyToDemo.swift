import GLMap
import GLMapSwift
import UIKit

class FlyToDemo: DemoMapViewController {
    private let destinations: [(name: String, point: GLMapGeoPoint)] = [
        ("Porto", GLMapGeoPoint(lat: 41.1579, lon: -8.6291)),
        ("San Sebastián", GLMapGeoPoint(lat: 43.3183, lon: -1.9812)),
        ("Lucerne", GLMapGeoPoint(lat: 47.0502, lon: 8.3093)),
        ("Bruges", GLMapGeoPoint(lat: 51.2093, lon: 3.2247)),
        ("Dubrovnik", GLMapGeoPoint(lat: 42.6507, lon: 18.0944)),
        ("Tallinn", GLMapGeoPoint(lat: 59.4370, lon: 24.7536)),
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
