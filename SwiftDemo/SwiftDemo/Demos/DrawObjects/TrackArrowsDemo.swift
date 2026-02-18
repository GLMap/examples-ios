import GLMap
import GLMapSwift
import UIKit

class TrackArrowsDemo: DemoMapViewController {
    private var routeTrack: GLMapTrack?

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        let points = [
            GLMapGeoPoint(lat: 53.8869, lon: 27.7151),  // Minsk
            GLMapGeoPoint(lat: 52.2251, lon: 21.0103),   // Warsaw
            GLMapGeoPoint(lat: 52.5037, lon: 13.4102),   // Berlin
            GLMapGeoPoint(lat: 48.8505, lon: 2.3343),    // Paris
        ]

        let mapPoints = points.map { GLMapPoint(geoPoint: $0) }
        let pointArray = GLMapPointArray(mapPoints)

        let routeColor = GLMapColor(red: 50, green: 200, blue: 0, alpha: 200)
        let routeStyle = GLMapVectorStyle.createStyle("{width: 7pt; fill-image:\"track-arrow.svg\";}")!

        var trackPoints = mapPoints.map { GLTrackPoint(pt: $0, color: routeColor) }
        if let trackData = GLMapTrackData(points: &trackPoints, count: UInt(trackPoints.count)) {
            let track = GLMapTrack(drawOrder: 5)
            track.setData(trackData, style: routeStyle)
            map.add(track)
            routeTrack = track
        }

        // Fit map to show the track
        var bbox = GLMapBBox.empty
        for pt in mapPoints {
            bbox.add(point: pt)
        }
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox) * 0.8

        // Also show as a vector line
        let lineStyle = GLMapVectorCascadeStyle.createStyle("line{width: 2pt; color:green;}")
        if let lineStyle {
            let vectorLayer = GLMapVectorLayer()
            vectorLayer.setVectorObject(GLMapVectorLine(line: pointArray), with: lineStyle)
            map.add(vectorLayer)
        }
    }
}
