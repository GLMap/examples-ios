import GLMap
import GLMapSwift
import GLRoute
import UIKit

class TrackArrowsDemo: DemoMapViewController {
    private var routeTrack: GLMapTrack?
    private var maneuverArrow: GLMapLineArrow?
    private var requestID: Int64 = 0
    private var requestGeneration = 0

    // Short scenic route: Amalfi Coast
    private let routeStart = GLMapGeoPoint(lat: 40.633, lon: 14.502)
    private let routeEnd = GLMapGeoPoint(lat: 40.650, lon: 14.720)

    override func viewDidLoad() {
        super.viewDidLoad()

        map.mapGeoCenter = GLMapGeoPoint(lat: 40.640, lon: 14.610)
        map.mapZoomLevel = 12

        title = "Building route..."
        setupManeuverArrow()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if routeTrack == nil, requestID == 0 {
            buildRoute()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        requestGeneration += 1
        if requestID != 0 {
            GLRouteRequest.cancel(requestID)
        }
        requestID = 0
    }

    private func buildRoute() {
        let request = GLRouteRequest()
        request.setAutoWithOptions(.default)
        request.add(GLRoutePoint(pt: routeStart, heading: .nan, type: .break))
        request.add(GLRoutePoint(pt: routeEnd, heading: .nan, type: .break))

        requestGeneration += 1
        let generation = requestGeneration
        requestID = request.startOnline { [weak self] route, error in
            guard let self, requestGeneration == generation else { return }
            requestID = 0
            guard let route,
                  let trackData = route.trackData(with: GLMapColor(red: 66, green: 133, blue: 244, alpha: 220))
            else {
                title = "Route failed"
                showAlert("Routing Error", message: error?.localizedDescription ?? "No route is available.")
                return
            }

            // fill-image repeats the small arrows over the entire track.
            let trackStyle = GLMapVectorStyle.createStyle("{width:14pt; fill-image:\"track-arrow.svg\";}")!
            let track = GLMapTrack(drawOrder: 5)
            track.setData(trackData, style: trackStyle)
            map.add(track)
            routeTrack = track

            title = "Track Arrows"
            // GLMapLineArrow draws one prominent arrow at a route maneuver.
            guard route.allManeuvers.count > 2 else { return }
            let maneuver = route.allManeuvers[1]
            maneuverArrow?.setLine(maneuver.line, index: maneuver.lineStartIndex)

            map.animate { anim in
                anim.flyToMode = .enabled
                anim.duration = 1.5
                self.map.mapCenter = maneuver.startPoint
                self.map.mapZoomLevel = 17
            }
        }
    }

    private func setupManeuverArrow() {
        let blue = GLMapColor(red: 66, green: 133, blue: 244, alpha: 255)
        guard let path = svgPath("route-maneuver-head"),
              let head = GLMapVectorImageFactory.shared.image(fromSvg: path, withScale: 1, andTintColor: blue),
              let style = GLMapVectorStyle.createStyle(
                  "{casing-width:2pt; casing-color:#4285F4FF; width:14pt; color:white; linecap:round;}"
              )
        else { return }

        let arrow = GLMapLineArrow(drawOrder: 6)
        arrow.setLineStyle(style, head: head)
        map.add(arrow)
        maneuverArrow = arrow
    }
}
