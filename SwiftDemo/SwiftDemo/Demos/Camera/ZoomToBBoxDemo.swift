import GLMap
import GLMapSwift
import UIKit

class ZoomToBBoxDemo: DemoMapViewController {
    private var vectorLayer: GLMapVectorLayer?
    private var bboxLayer: GLMapVectorLayer?

    /// Extra padding kept around the fitted bbox, on top of the safe area.
    private let visibleInset: CGFloat = 16

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

    private var didInitialFit = false

    /// Bounding box of all the city points.
    private var cityBBox: GLMapBBox {
        var bbox = GLMapBBox.empty
        for city in cities {
            bbox.add(point: GLMapPoint(lat: city.lat, lon: city.lon))
        }
        return bbox
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        // Keep a 16pt margin (plus the safe area) around whatever we fit into view.
        // `mapScale(for:)` below honors these insets automatically.
        map.visibleMapInsetsProvider = { [weak self] in
            guard let self else { return .zero }
            let safe = self.view.safeAreaInsets
            return UIEdgeInsets(
                top: safe.top + visibleInset,
                left: safe.left + visibleInset,
                bottom: safe.bottom + visibleInset,
                right: safe.right + visibleInset
            )
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Zoom to Fit", style: .plain, target: self, action: #selector(zoomToBBox)
        )

        drawCityMarkers()
        drawBBox()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Fit the bbox before the view is on screen — instantly, since the move
        // isn't visible yet. (A visible move should be animated; see the button.)
        if !didInitialFit, view.window != nil {
            didInitialFit = true
            fitBBox(animated: false)
        }
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
        fitBBox(animated: true)
    }

    private func fitBBox(animated: Bool) {
        let bbox = cityBBox
        drawBBox()

        if animated {
            map.animate { animation in
                animation.flyToMode = .enabled
                animation.duration = 2
                self.map.mapCenter = bbox.center
                self.map.mapScale = self.map.mapScale(for: bbox)
            }
        } else {
            map.mapCenter = bbox.center
            map.mapScale = map.mapScale(for: bbox)
        }
    }

    /// Draws the fitted bbox as a rectangle so it's easy to see how well the
    /// camera fits it inside the visible (inset) area.
    private func drawBBox() {
        let lats = cities.map { $0.lat }
        let lons = cities.map { $0.lon }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }

        // GeoJSON polygon ring (lon, lat), closed.
        let geoJSON = """
        {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[\
        [\(minLon),\(minLat)],[\(maxLon),\(minLat)],[\(maxLon),\(maxLat)],\
        [\(minLon),\(maxLat)],[\(minLon),\(minLat)]]]}}
        """
        guard let objects = try? GLMapVectorObject.createVectorObjects(fromGeoJSON: geoJSON) else { return }

        let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#3498DB33; width:2pt; color:#2980B9;}")!

        if let bboxLayer {
            bboxLayer.setVectorObjects(objects, with: style)
        } else {
            let layer = GLMapVectorLayer(drawOrder: 4)
            layer.setVectorObjects(objects, with: style)
            map.add(layer)
            bboxLayer = layer
        }
    }
}
