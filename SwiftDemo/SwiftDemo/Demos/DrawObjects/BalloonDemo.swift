import GLMap
import GLMapSwift
import UIKit

class BalloonDemo: DemoMapViewController {
    private var balloon: GLMapBalloon?
    private let pinImage = GLMapImage(drawOrder: 3)

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14

        if let image = UIImage(named: "pin1.png") {
            pinImage.setImage(image)
            pinImage.offset = CGPoint(x: image.size.width / 2, y: 0)
            pinImage.position = GLMapPoint(geoPoint: GLMapGeoPoint(lat: 37.3257, lon: -122.0353))
            map.add(pinImage)
        }

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let pt = gesture.location(in: map)
            let mapPt = map.makeMapPoint(fromDisplay: pt)

            if let oldBalloon = balloon {
                map.remove(oldBalloon)
                balloon = nil
            }

            let newBalloon = GLMapBalloon(drawOrder: 10)
            let style = GLMapVectorStyle.createStyle("{text-color:black;font-size:14;}")!
            let geoPt = GLMapGeoPoint(point: mapPt)
            newBalloon.setText(
                String(format: "%.4f, %.4f", geoPt.lat, geoPt.lon),
                with: style,
                insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            )
            newBalloon.position = mapPt
            map.add(newBalloon)
            balloon = newBalloon
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let balloon { map.remove(balloon) }
        map.remove(pinImage)
    }
}
