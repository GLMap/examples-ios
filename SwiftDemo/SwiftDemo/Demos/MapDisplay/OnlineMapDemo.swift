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

        loadStyle(options: ["Style": "Outdoor", "SubStyle": "Ski"])
        setupSegmentedControl()
        setupTapGesture()
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

            let text = String(format: "%.4f, %.4f", geoPt.lat, geoPt.lon)
            let style = GLMapVectorStyle.createStyle("{text-color:#2C3E50;font-size:14;font-stroke-width:0;}")!
            let balloon = balloon ?? {
                let newBalloon = GLMapBalloon(drawOrder: 10)
                let image = UIImage(named: "balloon")!
                let vInset = floor(image.size.height / 2)
                let hInset = floor(image.size.width / 2)
                newBalloon.setBackgroundImage(image, insets: UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset))
                self.balloon = newBalloon
                self.map.add(newBalloon)
                return newBalloon
            }()
            balloon.setText(text, with: style, insets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
            balloon.position = mapPt
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let balloon { map.remove(balloon) }
        map.base = GLMapVectorTileSource()
        osmTileSource = nil
    }
}
