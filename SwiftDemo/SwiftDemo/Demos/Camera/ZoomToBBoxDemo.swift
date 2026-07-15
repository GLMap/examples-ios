import GLMap
import GLMapSwift
import UIKit

class ZoomToBBoxDemo: DemoMapViewController {
    private let cityPoints = [
        GLMapPoint(lat: 52.5037, lon: 13.4102), // Berlin
        GLMapPoint(lat: 48.8505, lon: 2.3343), // Paris
        GLMapPoint(lat: 51.5072, lon: -0.1275), // London
        GLMapPoint(lat: 41.8933, lon: 12.4829), // Rome
        GLMapPoint(lat: 40.4168, lon: -3.7038), // Madrid
        GLMapPoint(lat: 52.2251, lon: 21.0103), // Warsaw
        GLMapPoint(lat: 48.2082, lon: 16.3738), // Vienna
        GLMapPoint(lat: 50.0755, lon: 14.4378), // Prague
    ]
    private var didInitialFit = false

    private var cityBBox: GLMapBBox {
        var bbox = GLMapBBox.empty
        for point in cityPoints { bbox.add(point: point) }
        return bbox
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        map.visibleMapInsetsProvider = { [weak self] in
            guard let self else { return .zero }
            let safe = view.safeAreaInsets
            return UIEdgeInsets(
                top: safe.top + 16,
                left: safe.left + 16,
                bottom: safe.bottom + 16,
                right: safe.right + 16
            )
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Zoom to Fit", style: .plain, target: self, action: #selector(zoomToBBox)
        )

        let style = GLMapVectorCascadeStyle.createStyle("line{width:4pt; color:#E74C3C;}")!
        let layer = GLMapVectorLayer(drawOrder: 5)
        layer.setVectorObject(GLMapVectorLine(line: GLMapPointArray(cityPoints)), with: style)
        map.add(layer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didInitialFit, view.window != nil {
            didInitialFit = true
            fitBBox(animated: false)
        }
    }

    @objc private func zoomToBBox() {
        fitBBox(animated: true)
    }

    private func fitBBox(animated: Bool) {
        let bbox = cityBBox
        let updateCamera = {
            self.map.mapCenter = bbox.center
            self.map.mapScale = self.map.mapScale(for: bbox)
        }
        if animated {
            map.animate { animation in
                animation.flyToMode = .enabled
                animation.duration = 2
                updateCamera()
            }
        } else {
            updateCamera()
        }
    }
}
