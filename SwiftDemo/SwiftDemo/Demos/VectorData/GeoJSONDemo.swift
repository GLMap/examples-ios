import GLMap
import GLMapSwift
import UIKit

class GeoJSONDemo: DemoMapViewController {
    override var usesOnlineTiles: Bool {
        false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Loading GeoJSON..."

        guard let path = Bundle.main.path(forResource: "uk_postcodes", ofType: "geojson") else {
            title = "GeoJSON failed"
            showAlert(message: "uk_postcodes.geojson not found in bundle")
            return
        }

        // File I/O and parsing of the large sample must not block opening the screen.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let objects = try GLMapVectorObject.createVectorObjects(fromFile: path)
                DispatchQueue.main.async { self?.display(objects) }
            } catch {
                DispatchQueue.main.async {
                    self?.title = "GeoJSON failed"
                    self?.showAlert(message: "GeoJSON error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func display(_ objects: GLMapVectorObjectArray) {
        let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#3498DB40; width:1.5pt; color:#2C3E50;}")!
        let vectorLayer = GLMapVectorLayer()
        // Updates and their completion run on the main thread. Ready means the
        // geometry is ready to draw, not that a frame has already been presented.
        vectorLayer.setVectorObjects(objects, with: style) { [weak self] result in
            guard let self else { return }
            switch result {
            case .ready:
                title = "Tap on any UK region"
            case .failed:
                title = "GeoJSON failed"
                showAlert(message: "Cannot prepare GeoJSON for drawing")
            case .superseded, .cancelled:
                title = "GeoJSON"
            @unknown default:
                break
            }
        }
        map.add(vectorLayer)
        let bbox = objects.bbox
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox)

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let mapPoint = map.makeMapPoint(fromDisplay: gesture.location(in: map))
            let delta = map.makeMapPoint(fromDisplayDelta: CGPoint(x: 0, y: 10))
            let maxDistance = hypot(delta.x, delta.y)
            for index in 0 ..< objects.count {
                let object = objects[index]
                var point = mapPoint
                if object.findNearestPoint(&point, to: mapPoint, maxDistance: maxDistance) {
                    showAlert(message: "Tapped: \(object.debugDescription())")
                    return
                }
            }
        }
    }
}
