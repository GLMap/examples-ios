import GLMap
import GLMapSwift
import UIKit

class ZoomToBBoxDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Zoom", style: .plain, target: self, action: #selector(zoomToBBox)
        )

        zoomToBBox()
    }

    @objc private func zoomToBBox() {
        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(lat: 52.5037, lon: 13.4102))  // Berlin
        bbox.add(point: GLMapPoint(lat: 53.9024, lon: 27.5618))  // Minsk

        map.animate { animation in
            animation.flyToMode = .enabled
            self.map.mapCenter = bbox.center
            self.map.mapScale = self.map.mapScale(for: bbox)
        }
    }
}
