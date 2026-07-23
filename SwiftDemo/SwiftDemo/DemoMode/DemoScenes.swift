import GLMap
import GLMapSwift
import GLRoute
import UIKit

enum DemoScenes {
    // Scenic area: Amalfi Coast, Italy
    private static let scenicCenter = GLMapGeoPoint(lat: 40.633, lon: 14.602)
    private static let routeStart = GLMapGeoPoint(lat: 40.633, lon: 14.502)
    private static let routeEnd = GLMapGeoPoint(lat: 40.650, lon: 14.720)

    static let all: [DemoScene] = [
        // 1. Title card
        DemoScene { vc, completion in
            vc.overlay.showTitle("GLMap 2.0", subtitle: "SDK Demo")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                vc.overlay.hideTitle()
                completion()
            }
        },

        // 2. Globe zoom — fly to scenic area
        DemoScene { vc, completion in
            vc.map.animate { anim in
                anim.flyToMode = .enabled
                anim.duration = 4.5
                vc.map.mapGeoCenter = scenicCenter
                vc.map.mapZoomLevel = 12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { completion() }
        },

        // 3. 3D terrain reveal
        DemoScene(caption: "3D Terrain") { vc, completion in
            vc.map.animate { anim in
                anim.duration = 5.5
                vc.map.mapPitch = 45
                vc.map.altitudeScale = 1.5
            }
            vc.map.drawHillshades = true
            vc.map.drawElevationLines = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { completion() }
        },

        // 4. Terrain flight — fly along coastline
        DemoScene(caption: "3D Terrain") { vc, completion in
            vc.map.animate { anim in
                anim.duration = 9.5
                anim.transition = .linear
                vc.map.mapGeoCenter = GLMapGeoPoint(lat: 40.650, lon: 14.720)
                vc.map.mapAngle = 45
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { completion() }
        },

        // 5. Dark theme switch
        DemoScene(caption: "Dark Theme") { vc, completion in
            vc.loadDarkStyle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { completion() }
        },

        // 6. Night flight
        DemoScene(caption: "Dark Theme") { vc, completion in
            vc.map.animate { anim in
                anim.duration = 7.5
                anim.transition = .linear
                vc.map.mapGeoCenter = GLMapGeoPoint(lat: 40.633, lon: 14.502)
                vc.map.mapAngle = -45
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { completion() }
        },

        // 7. Reset to 2D
        DemoScene { vc, completion in
            vc.loadLightStyle()
            vc.map.animate { anim in
                anim.duration = 2.5
                vc.map.mapPitch = 0
                vc.map.altitudeScale = 0
                vc.map.mapAngle = 0
            }
            vc.map.drawHillshades = false
            vc.map.drawElevationLines = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { completion() }
        },

        // 8. Marker clusters
        DemoScene(caption: "Marker Clustering") { vc, completion in
            vc.showMarkerClusters()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                vc.map.animate { anim in
                    anim.duration = 3.5
                    anim.flyToMode = .enabled
                    vc.map.mapZoomLevel = 8
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { completion() }
        },

        // 9. Route overlay — shown over the default 3D terrain view
        DemoScene(caption: "Routing") { vc, completion in
            vc.clearOverlays()
            vc.map.drawHillshades = true
            vc.map.drawElevationLines = true
            vc.map.animate { anim in
                anim.flyToMode = .enabled
                anim.duration = 2
                vc.map.mapGeoCenter = GLMapGeoPoint(lat: 40.640, lon: 14.610)
                vc.map.mapZoomLevel = 12
                vc.map.mapPitch = 45
                vc.map.altitudeScale = 1.5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                vc.buildDemoRoute(from: routeStart, to: routeEnd)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { completion() }
        },

        // 10. Route flight — camera follows route
        DemoScene(caption: "Routing") { vc, completion in
            vc.map.animate { anim in
                anim.duration = 2
                vc.map.mapPitch = 45
                vc.map.mapZoomLevel = 14
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                vc.map.animate { anim in
                    anim.duration = 12
                    anim.transition = .linear
                    vc.map.mapGeoCenter = routeEnd
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { completion() }
        },

        // 11. Online search — category results around the scenic area
        DemoScene(caption: "Search") { vc, completion in
            vc.clearOverlays()
            vc.map.animate { anim in
                anim.duration = 2
                vc.map.mapPitch = 0
            }
            vc.showOnlineSearchResults(at: scenicCenter)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { completion() }
        },

        // 12. End card — zoom out to globe
        DemoScene { vc, completion in
            vc.clearOverlays()
            vc.map.animate { anim in
                anim.flyToMode = .enabled
                anim.duration = 3
                vc.map.mapZoomLevel = 2
                vc.map.mapGeoCenter = GLMapGeoPoint(lat: 30, lon: 10)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                vc.overlay.showTitle("globus.software", subtitle: nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { completion() }
        },
    ]
}
