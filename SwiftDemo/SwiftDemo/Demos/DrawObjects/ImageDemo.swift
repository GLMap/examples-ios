import GLMap
import GLMapSwift
import UIKit

class ImageDemo: DemoMapViewController {
    private let mapImage = GLMapImage(drawOrder: 3)

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 48.8566, lon: 2.3522) // Paris
        map.mapZoomLevel = 7
        title = "Tap map to move the image"

        guard let path = Bundle.main.path(forResource: "pin", ofType: "svg"),
              let image = GLMapVectorImageFactory.shared.image(
                  fromSvg: path,
                  withScale: 1.6,
                  andTintColor: GLMapColor(red: 230, green: 60, blue: 60, alpha: 255)
              ) else { return }
        mapImage.setImage(image)
        mapImage.offset = CGPoint(x: image.size.width / 2, y: 0)
        mapImage.position = GLMapPoint(geoPoint: map.mapGeoCenter)
        map.add(mapImage)

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let position = map.makeMapPoint(fromDisplay: gesture.location(in: map))
            map.animate { animation in
                animation.duration = 0.3
                self.mapImage.position = position
            }
        }
    }
}
