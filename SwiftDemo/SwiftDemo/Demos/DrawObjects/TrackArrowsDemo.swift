import GLMap
import GLMapSwift
import GLRoute
import UIKit

class TrackArrowsDemo: DemoMapViewController {
    private var routeTrack: GLMapTrack?
    private var requestID: Int64 = 0

    // Short scenic route: Amalfi Coast
    private let routeStart = GLMapGeoPoint(lat: 40.633, lon: 14.502)
    private let routeEnd = GLMapGeoPoint(lat: 40.650, lon: 14.720)

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        map.mapGeoCenter = GLMapGeoPoint(lat: 40.640, lon: 14.610)
        map.mapZoomLevel = 12

        title = "Building route..."
        buildRoute()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if requestID != 0 { GLRouteRequest.cancel(requestID) }
        requestID = 0
    }

    private func buildRoute() {
        let request = GLRouteRequest()
        request.setAutoWithOptions(CostingOptionsAuto())
        request.add(GLRoutePoint(pt: routeStart, heading: .nan, type: .break))
        request.add(GLRoutePoint(pt: routeEnd, heading: .nan, type: .break))

        let routeStyle = GLMapVectorStyle.createStyle("{width: 14pt; fill-image:\"track-arrow.svg\";}")!

        requestID = request.startOnline { [weak self] route, _ in
            guard let self, requestID != 0, let route,
                  let trackData = route.trackData(with: GLMapColor(red: 66, green: 133, blue: 244, alpha: 220))
            else {
                if self?.requestID != 0 { self?.title = "Route failed — check network" }
                return
            }
            requestID = 0

            let track = GLMapTrack(drawOrder: 5)
            track.setData(trackData, style: routeStyle)
            map.add(track)
            routeTrack = track
            title = "Track Arrows"

            // Zoom to route
            let bbox = route.bbox
            map.animate { anim in
                anim.flyToMode = .enabled
                anim.duration = 1.5
                self.map.mapCenter = bbox.center
                self.map.mapScale = self.map.mapScale(for: bbox)
            }
        }
    }
}
