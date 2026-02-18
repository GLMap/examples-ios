import GLMap
import GLMapSwift
import UIKit

class LinesPolygonsDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Multiline: European cities
        let line1 = GLMapPointArray([
            GLMapPoint(lat: 53.8869, lon: 27.7151),  // Minsk
            GLMapPoint(lat: 50.4339, lon: 30.5186),   // Kiev
            GLMapPoint(lat: 52.2251, lon: 21.0103),   // Warsaw
            GLMapPoint(lat: 52.5037, lon: 13.4102),   // Berlin
            GLMapPoint(lat: 48.8505, lon: 2.3343),    // Paris
        ])
        let line2 = GLMapPointArray([
            GLMapPoint(lat: 52.3690, lon: 4.9021),    // Amsterdam
            GLMapPoint(lat: 50.8263, lon: 4.3458),    // Brussels
            GLMapPoint(lat: 49.6072, lon: 6.1296),    // Luxembourg
        ])

        if let lineStyle = GLMapVectorCascadeStyle.createStyle("line{width: 3pt; color:green;}") {
            let lineLayer = GLMapVectorLayer()
            lineLayer.setVectorObject(GLMapVectorLine(lines: [line1, line2]), with: lineStyle)
            map.add(lineLayer)
        }

        // Polygon: star shape centered on Europe
        let center = GLMapGeoPoint(lat: 50, lon: 15)
        let pointCount = 25
        let radiusOuter = 8.0
        let radiusInner = 4.0
        let sectorSize = 2 * Double.pi / Double(pointCount)

        let outerRing = GLMapPointArray(count: UInt(pointCount)) { i in
            GLMapPoint(
                lat: center.lat + cos(sectorSize * Double(i)) * radiusOuter,
                lon: center.lon + sin(sectorSize * Double(i)) * radiusOuter
            )
        }
        let innerRing = GLMapPointArray(count: UInt(pointCount)) { i in
            GLMapPoint(
                lat: center.lat + cos(sectorSize * Double(i)) * radiusInner,
                lon: center.lon + sin(sectorSize * Double(i)) * radiusInner
            )
        }

        if let polyStyle = GLMapVectorCascadeStyle.createStyle("area{fill-color:#10106050; width:3pt; color:blue;}") {
            let polyLayer = GLMapVectorLayer()
            polyLayer.setVectorObject(GLMapVectorPolygon([outerRing], innerRings: [innerRing]), with: polyStyle)
            map.add(polyLayer)
        }

        map.mapGeoCenter = center
        map.mapZoomLevel = 4
    }
}
