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
            let mapPt = map.makeMapPoint(fromDisplay: pt)
            let geoPt = GLMapGeoPoint(point: mapPt)

            if let oldBalloon = balloon {
                map.remove(oldBalloon)
                balloon = nil
            }

            // Search for the nearest POI at the tap location
            let search = GLSearch()
            search.center = mapPt
            search.limit = 1
            search.setLocaleSettings(map.localeSettings)

            search.searchAsync { [weak self] results in
                guard let self, results.count > 0 else { return }

                DispatchQueue.main.async {
                    let obj = results[0]
                    let name = obj.localizedName(self.map.localeSettings)?.asString() ?? ""

                    let newBalloon = GLMapBalloon(drawOrder: 10)
                    let style = GLMapVectorStyle.createStyle("{text-color:black;font-size:14;}")!
                    newBalloon.setText(
                        name.isEmpty ? String(format: "%.4f, %.4f", geoPt.lat, geoPt.lon) : name,
                        with: style,
                        insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
                    )
                    newBalloon.position = mapPt
                    self.map.add(newBalloon)
                    self.balloon = newBalloon
                    self.title = name.isEmpty ? "Unknown" : name
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let balloon { map.remove(balloon) }
    }
}
