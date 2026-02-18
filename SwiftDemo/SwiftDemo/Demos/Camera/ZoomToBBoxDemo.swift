import GLMap
import GLMapSwift
import UIKit

class ZoomToBBoxDemo: DemoMapViewController {
    private var vectorLayer: GLMapVectorLayer?

    private let cities: [(name: String, lat: Double, lon: Double)] = [
        ("Berlin", 52.5037, 13.4102),
        ("Paris", 48.8505, 2.3343),
        ("London", 51.5072, -0.1275),
        ("Rome", 41.8933, 12.4829),
        ("Madrid", 40.4168, -3.7038),
        ("Warsaw", 52.2251, 21.0103),
        ("Vienna", 48.2082, 16.3738),
        ("Prague", 50.0755, 14.4378),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 50, lon: 10)
        map.mapZoomLevel = 4

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Zoom to Fit", style: .plain, target: self, action: #selector(zoomToBBox)
        )

        drawCityMarkers()
    }

    private func drawCityMarkers() {
        // Create points + labels for each city using GeoJSON
        var geoJSON = "{\"type\":\"FeatureCollection\",\"features\":["
        for (i, city) in cities.enumerated() {
            if i > 0 { geoJSON += "," }
            geoJSON += """
            {"type":"Feature","geometry":{"type":"Point","coordinates":[\(city.lon),\(city.lat)]},"properties":{"name":"\(city.name)"}}
            """
        }
        geoJSON += "]}"

        guard let objects = try? GLMapVectorObject.createVectorObjects(fromGeoJSON: geoJSON) else { return }

        let style = GLMapVectorCascadeStyle.createStyle("""
        node{
            icon-image:"circle_new.svg";
            icon-scale:0.3;
            icon-tint:#FF4444;
            text:eval(tag('name'));
            text-color:#333333;
            font-size:12;
            font-stroke-width:1pt;
            font-stroke-color:#FFFFFFCC;
            text-priority:100;
        }
        """)!

        let layer = GLMapVectorLayer(drawOrder: 5)
        layer.setVectorObjects(objects, with: style)
        map.add(layer)
        vectorLayer = layer
    }

    @objc private func zoomToBBox() {
        // Compute bbox from the city points
        var bbox = GLMapBBox.empty
        for city in cities {
            bbox.add(point: GLMapPoint(lat: city.lat, lon: city.lon))
        }

        map.animate { animation in
            animation.flyToMode = .enabled
            animation.duration = 2
            self.map.mapCenter = bbox.center
            self.map.mapScale = self.map.mapScale(for: bbox)
        }
    }
}
