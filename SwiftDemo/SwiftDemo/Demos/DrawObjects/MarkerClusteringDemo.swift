import GLMap
import GLMapSwift
import UIKit

class MarkerClusteringDemo: DemoMapViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let imagePath = svgPath("cluster") else { return }

        let tintColors = [
            GLMapColor(red: 33, green: 0, blue: 255, alpha: 255),
            GLMapColor(red: 68, green: 195, blue: 255, alpha: 255),
            GLMapColor(red: 63, green: 237, blue: 198, alpha: 255),
            GLMapColor(red: 15, green: 228, blue: 36, alpha: 255),
            GLMapColor(red: 168, green: 238, blue: 25, alpha: 255),
            GLMapColor(red: 214, green: 234, blue: 25, alpha: 255),
            GLMapColor(red: 223, green: 180, blue: 19, alpha: 255),
            GLMapColor(red: 255, green: 0, blue: 0, alpha: 255),
        ]

        let styleCollection = GLMapMarkerStyleCollection()
        var maxWidth = 0.0

        for (i, color) in tintColors.enumerated() {
            let scale = 0.2 + 0.1 * Double(i)
            if let image = GLMapVectorImageFactory.shared.image(fromSvg: imagePath, withScale: scale, andTintColor: color) {
                maxWidth = max(maxWidth, Double(image.size.width))
                styleCollection.addStyle(with: image)
            }
        }

        let textStyle = GLMapVectorStyle.createStyle("{text-color:black;font-size:12;font-stroke-width:1pt;font-stroke-color:#FFFFFFEE;}")!

        styleCollection.setMarkerDataFill { marker, data in
            if let obj = marker as? GLMapVectorObject {
                data.setStyle(0)
                if let name = obj.value(forKey: "name")?.asString() {
                    data.setText(name, offset: CGPoint(x: 0, y: 8), style: textStyle)
                }
            }
        }

        styleCollection.setMarkerUnionFill { markerCount, data in
            var styleIndex = Int(log2(Double(markerCount)))
            styleIndex = min(styleIndex, tintColors.count - 1)
            data.setStyle(UInt32(styleIndex))
            data.setText("\(markerCount)", offset: .zero, style: textStyle)
        }

        DispatchQueue.global().async { [weak self] in
            guard let dataPath = Bundle.main.path(forResource: "cluster_data", ofType: "json"),
                  let objects = try? GLMapVectorObject.createVectorObjects(fromFile: dataPath) else { return }

            let markerLayer = GLMapMarkerLayer(
                vectorObjects: objects,
                andStyles: styleCollection,
                clusteringRadius: maxWidth / 2,
                drawOrder: 2
            )
            let bbox = objects.bbox

            DispatchQueue.main.async {
                self?.map.add(markerLayer)
                self?.map.mapCenter = bbox.center
                self?.map.mapScale = self?.map.mapScale(for: bbox) ?? 0
            }
        }
    }
}
