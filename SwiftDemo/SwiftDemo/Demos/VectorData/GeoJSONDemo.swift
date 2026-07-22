import GLMap
import GLMapSwift
import UIKit

class GeoJSONDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tap on any UK region"

        guard let path = Bundle.main.path(forResource: "uk_postcodes", ofType: "geojson") else {
            showAlert(message: "uk_postcodes.geojson not found in bundle")
            return
        }

        do {
            let objects = try GLMapVectorObject.createVectorObjects(fromFile: path)
            let style = GLMapVectorCascadeStyle.createStyle("area{fill-color:#3498DB40; width:1.5pt; color:#2C3E50;}")!

            let vectorLayer = GLMapVectorLayer()
            vectorLayer.setVectorObjects(objects, with: style)
            map.add(vectorLayer)

            let bbox = objects.bbox
            map.mapCenter = bbox.center
            map.mapScale = map.mapScale(for: bbox)

            map.tapGestureBlock = { [weak self] gesture in
                guard let self else { return }
                let mapPoint = map.makeMapPoint(fromDisplay: gesture.location(in: map))
                let tmp = map.makeMapPoint(fromDisplayDelta: CGPoint(x: 0, y: 10))
                let maxDist = hypot(tmp.x, tmp.y)

                for index in 0 ..< objects.count {
                    let object = objects[index]
                    var pt = mapPoint
                    if object.findNearestPoint(&pt, to: mapPoint, maxDistance: maxDist) {
                        showAlert(message: "Tapped: \(object.debugDescription())")
                        return
                    }
                }
            }
        } catch {
            showAlert(message: "GeoJSON error: \(error.localizedDescription)")
        }
    }
}
