import GLMap
import GLMapSwift
import UIKit

class OnlineMapDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14
    }
}
