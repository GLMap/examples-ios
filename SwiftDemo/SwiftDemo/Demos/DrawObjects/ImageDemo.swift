import GLMap
import GLMapSwift
import UIKit

class ImageDemo: DemoMapViewController {
    private let mapImage = GLMapImage(drawOrder: 3)

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14

        if let image = UIImage(named: "pin1.png") {
            mapImage.setImage(image)
            mapImage.offset = CGPoint(x: image.size.width / 2, y: 0)
            mapImage.hidden = true
            map.add(mapImage)
        }

        let barButton = UIBarButtonItem(title: "Add Image", style: .plain, target: self, action: #selector(imageTap))
        navigationItem.rightBarButtonItem = barButton
        imageTap(barButton)
    }

    @objc private func imageTap(_ button: UIBarButtonItem) {
        switch button.title {
        case "Add Image":
            mapImage.hidden = false
            mapImage.position = map.mapCenter
            mapImage.angle = Float(arc4random_uniform(360))
            button.title = "Move Image"

        case "Move Image":
            map.animate { _ in
                self.mapImage.position = self.map.mapCenter
                self.mapImage.angle = Float(arc4random_uniform(360))
            }
            button.title = "Remove Image"

        case "Remove Image":
            mapImage.hidden = true
            button.title = "Add Image"

        default: break
        }
    }
}
