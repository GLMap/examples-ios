import GLMap
import GLMapSwift
import UIKit

class ImageDemo: DemoMapViewController {
    private let mapImage = GLMapImage(drawOrder: 3)
    private var destinations: [GLMapGeoPoint] = []
    private var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 48.8566, lon: 2.3522) // Paris
        map.mapZoomLevel = 5

        destinations = [
            GLMapGeoPoint(lat: 48.8566, lon: 2.3522),   // Paris
            GLMapGeoPoint(lat: 51.5072, lon: -0.1275),   // London
            GLMapGeoPoint(lat: 52.5037, lon: 13.4102),   // Berlin
            GLMapGeoPoint(lat: 41.8933, lon: 12.4829),   // Rome
            GLMapGeoPoint(lat: 40.4168, lon: -3.7038),   // Madrid
        ]

        if let image = UIImage(named: "pin1.png") {
            mapImage.setImage(image)
            mapImage.offset = CGPoint(x: image.size.width / 2, y: 0)
            mapImage.position = GLMapPoint(geoPoint: destinations[0])
            map.add(mapImage)
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Fly to Next", style: .plain, target: self, action: #selector(flyToNext)
        )
    }

    @objc private func flyToNext() {
        currentIndex = (currentIndex + 1) % destinations.count
        let dest = destinations[currentIndex]

        map.animate { anim in
            anim.flyToMode = .enabled
            anim.duration = 1.5
            self.map.mapGeoCenter = dest
            anim.setPosition(GLMapPoint(geoPoint: dest), for: self.mapImage)
        }
    }
}
