import GLMap
import GLMapSwift
import UIKit

class LinesPolygonsDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        let center = GLMapGeoPoint(lat: 48.8566, lon: 2.3522) // Paris
        map.mapGeoCenter = center
        map.mapZoomLevel = 5

        drawEuropeanRoutes()
        drawStar(center: center)
        drawPolygon()
    }

    private func drawEuropeanRoutes() {
        // Route 1: London → Paris → Madrid (warm colors)
        let route1 = GLMapPointArray([
            GLMapPoint(lat: 51.5072, lon: -0.1275), // London
            GLMapPoint(lat: 48.8566, lon: 2.3522), // Paris
            GLMapPoint(lat: 46.2044, lon: 6.1432), // Geneva
            GLMapPoint(lat: 41.8933, lon: 12.4829), // Rome
        ])

        // Route 2: Berlin → Prague → Vienna → Budapest (cool colors)
        let route2 = GLMapPointArray([
            GLMapPoint(lat: 52.5037, lon: 13.4102), // Berlin
            GLMapPoint(lat: 50.0755, lon: 14.4378), // Prague
            GLMapPoint(lat: 48.2082, lon: 16.3738), // Vienna
            GLMapPoint(lat: 47.4979, lon: 19.0402), // Budapest
        ])

        // Route 3: Amsterdam → Brussels → Luxembourg
        let route3 = GLMapPointArray([
            GLMapPoint(lat: 52.3690, lon: 4.9021), // Amsterdam
            GLMapPoint(lat: 50.8263, lon: 4.3458), // Brussels
            GLMapPoint(lat: 49.6072, lon: 6.1296), // Luxembourg
            GLMapPoint(lat: 48.8566, lon: 2.3522), // Paris
        ])

        if let style = GLMapVectorCascadeStyle.createStyle("line{width: 4pt; color:#E74C3C;}") {
            let layer = GLMapVectorLayer(drawOrder: 3)
            layer.setVectorObject(GLMapVectorLine(line: route1), with: style)
            map.add(layer)
        }
        if let style = GLMapVectorCascadeStyle.createStyle("line{width: 4pt; color:#3498DB;}") {
            let layer = GLMapVectorLayer(drawOrder: 3)
            layer.setVectorObject(GLMapVectorLine(line: route2), with: style)
            map.add(layer)
        }
        if let style = GLMapVectorCascadeStyle.createStyle("line{width: 3pt; color:#2ECC71; linecap:round;}") {
            let layer = GLMapVectorLayer(drawOrder: 3)
            layer.setVectorObject(GLMapVectorLine(line: route3), with: style)
            map.add(layer)
        }
    }

    private func drawStar(center: GLMapGeoPoint) {
        // 5-pointed star around Paris
        let tips = 5
        let outerR = 3.0 // degrees
        let innerR = 1.2

        let starPoints = GLMapPointArray(count: UInt(tips * 2 + 1)) { i in
            let angle = Double(i) * .pi / Double(tips) - .pi / 2
            let r = (Int(i) % 2 == 0) ? outerR : innerR
            return GLMapPoint(
                lat: center.lat + r * sin(angle),
                lon: center.lon + r * cos(angle) / cos(center.lat * .pi / 180) // compensate for latitude
            )
        }

        if let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#F39C1230; width:2pt; color:#F39C12;}") {
            let layer = GLMapVectorLayer(drawOrder: 2)
            layer.setVectorObject(GLMapVectorPolygon([starPoints], innerRings: nil), with: style)
            map.add(layer)
        }
    }

    private func drawPolygon() {
        // Hexagonal region around Berlin with hole
        let berlinCenter = GLMapGeoPoint(lat: 52.5037, lon: 13.4102)
        let outerR = 1.5
        let innerR = 0.6

        let outer = GLMapPointArray(count: 7) { i in
            let angle = Double(i) * .pi / 3.0
            return GLMapPoint(
                lat: berlinCenter.lat + outerR * sin(angle),
                lon: berlinCenter.lon + outerR * cos(angle) / cos(berlinCenter.lat * .pi / 180)
            )
        }
        let inner = GLMapPointArray(count: 7) { i in
            let angle = Double(i) * .pi / 3.0
            return GLMapPoint(
                lat: berlinCenter.lat + innerR * sin(angle),
                lon: berlinCenter.lon + innerR * cos(angle) / cos(berlinCenter.lat * .pi / 180)
            )
        }

        if let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#9B59B630; width:2pt; color:#9B59B6;}") {
            let layer = GLMapVectorLayer(drawOrder: 2)
            layer.setVectorObject(GLMapVectorPolygon([outer], innerRings: [inner]), with: style)
            map.add(layer)
        }
    }
}
