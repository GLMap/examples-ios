import GLMap
import GLMapSwift
import UIKit

class BalloonDemo: DemoMapViewController {
    private var balloon: GLMapBalloon?
    private var pins: [GLMapImage] = []

    private let cities: [(name: String, lat: Double, lon: Double)] = [
        ("Eiffel Tower", 48.8584, 2.2945),
        ("Colosseum", 41.8902, 12.4922),
        ("Big Ben", 51.5007, -0.1246),
        ("Brandenburg Gate", 52.5163, 13.3777),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 48, lon: 8)
        map.mapZoomLevel = 5
        title = "Tap a pin to see balloon"

        // Place pins at landmarks
        guard let pinImg = UIImage(named: "pin1.png") else { return }
        for city in cities {
            let pin = GLMapImage(drawOrder: 3)
            pin.setImage(pinImg)
            pin.offset = CGPoint(x: pinImg.size.width / 2, y: 0)
            pin.position = GLMapPoint(lat: city.lat, lon: city.lon)
            map.add(pin)
            pins.append(pin)
        }

        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let displayPt = gesture.location(in: map)

            // Remove existing balloon
            if let oldBalloon = balloon {
                map.remove(oldBalloon)
                balloon = nil
            }

            // Find nearest pin
            var bestCity: (name: String, lat: Double, lon: Double)?
            var bestDist = Double.greatestFiniteMagnitude

            for city in cities {
                let cityDisplay = map.makeDisplayPoint(from: GLMapPoint(lat: city.lat, lon: city.lon))
                let dx = Double(cityDisplay.x - displayPt.x)
                let dy = Double(cityDisplay.y - displayPt.y)
                let dist = dx * dx + dy * dy
                if dist < bestDist, dist < 40 * 40 {
                    bestDist = dist
                    bestCity = city
                }
            }

            guard let city = bestCity else { return }

            let newBalloon = GLMapBalloon(drawOrder: 10)
            let style = GLMapVectorStyle.createStyle("{text-color:#2C3E50;font-size:16;font-stroke-width:0;}")!
            let image = UIImage(named: "balloon")!
            let vInset = floor(image.size.height / 2)
            let hInset = floor(image.size.width / 2)
            newBalloon.setBackgroundImage(image, insets: UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: hInset))
            newBalloon.setText(
                city.name,
                with: style,
                insets: UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
            )
            newBalloon.position = GLMapPoint(lat: city.lat, lon: city.lon)
            map.add(newBalloon)
            balloon = newBalloon
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let balloon { map.remove(balloon) }
        for pin in pins {
            map.remove(pin)
        }
    }
}
