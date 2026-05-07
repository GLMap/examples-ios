import GLMap
import GLMapSwift
import GLSearch
import UIKit

class POITapDemo: DemoMapViewController {
    private var balloon: GLMapBalloon?

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 48.8566, lon: 2.3522)
        map.mapZoomLevel = 16
        title = "Tap to find POI"

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let pt = gesture.location(in: map)
            if let oldBalloon = balloon {
                map.remove(oldBalloon)
                balloon = nil
            }

            if let object = map.state.mapObject(at: pt, maxDistance: 20) {
                let name = object.localizedName(self.map.localeSettings)?.asString() ?? ""
                let newBalloon = GLMapBalloon(drawOrder: 10)
                let style = GLMapVectorStyle.createStyle("{text-color:black;font-size:14;}")!
                let image = UIImage(named: "balloon")!
                let vInset = floor(image.size.height / 2)
                let hInset = floor(image.size.width / 2)
                let geoPt = GLMapGeoPoint(point: object.point)
                newBalloon.setBackgroundImage(image, insets: UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset))
                newBalloon.setText(
                    name.isEmpty ? String(format: "%.4f, %.4f", geoPt.lat, geoPt.lon) : name,
                    with: style,
                    insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
                )
                newBalloon.position = object.point
                self.map.add(newBalloon)
                self.balloon = newBalloon
                self.title = name.isEmpty ? "Unknown" : name
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let balloon { map.remove(balloon) }
    }
}
