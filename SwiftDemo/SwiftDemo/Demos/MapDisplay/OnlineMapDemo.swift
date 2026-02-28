import GLMap
import GLMapSwift
import UIKit

class OnlineMapDemo: DemoMapViewController {
    private var balloon: GLMapBalloon?
    private var osmTileSource: OSMTileSource?

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        // Cortina d'Ampezzo — Dolomites ski resort, great for hillshades and contour lines
        map.mapGeoCenter = GLMapGeoPoint(lat: 46.5369, lon: 12.1356)
        map.mapZoomLevel = 13
        map.drawElevationLines = true
        map.drawHillshades = true

        loadSkiStyle()
        setupSegmentedControl()
        setupTapGesture()
    }

    // MARK: - Style

    private func loadSkiStyle() {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        parser.setOptions(["Style": "Outdoor", "SubStyle": "Ski"], defaultValue: true)
        if let style = parser.parseFromResources() {
            map.setStyle(style)
        }
    }

    // MARK: - Tile source toggle

    private func setupSegmentedControl() {
        let segmented = UISegmentedControl(items: ["GLMap Vector", "OSM Raster"])
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(tileSourceChanged(_:)), for: .valueChanged)
        navigationItem.titleView = segmented
    }

    @objc private func tileSourceChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            map.base = GLMapVectorTileSource()
            map.drawElevationLines = true
            map.drawHillshades = true
            osmTileSource = nil
        } else if let source = OSMTileSource(cachePath: "osm_tiles.db") {
            map.base = source
            map.drawElevationLines = false
            map.drawHillshades = false
            osmTileSource = source
        }
    }

    // MARK: - Tap to show coordinates

    private func setupTapGesture() {
        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let displayPt = gesture.location(in: map)
            let mapPt = map.makeMapPoint(fromDisplay: displayPt)
            let geoPt = GLMapGeoPoint(point: mapPt)

            if let oldBalloon = balloon {
                map.remove(oldBalloon)
            }

            let newBalloon = GLMapBalloon(drawOrder: 10)
            let text = String(format: "%.4f, %.4f", geoPt.lat, geoPt.lon)
            let style = GLMapVectorStyle.createStyle("{text-color:#2C3E50;font-size:14;font-stroke-width:0;}")!
            newBalloon.setText(text, with: style, insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
            newBalloon.position = mapPt
            map.add(newBalloon)
            balloon = newBalloon
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let balloon { map.remove(balloon) }
        map.base = GLMapVectorTileSource()
        osmTileSource = nil
    }
}
