import GLMap
import GLMapSwift
import UIKit

class FlyToDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Fly", style: .plain, target: self, action: #selector(flyToRandom)
        )

        map.animate { animation in
            animation.flyToMode = .enabled
            self.map.mapZoomLevel = 14
            self.map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        }
    }

    @objc private func flyToRandom() {
        map.animate { animation in
            animation.flyToMode = .enabled
            self.map.mapZoomLevel = 14
            let lat = 33.0 + (48.0 - 33.0) * drand48()
            let lon = -118.0 + (-85.0 + 118.0) * drand48()
            self.map.mapGeoCenter = GLMapGeoPoint(lat: lat, lon: lon)
        }
    }
}
