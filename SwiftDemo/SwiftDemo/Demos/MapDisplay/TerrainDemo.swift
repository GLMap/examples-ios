import GLMap
import GLMapSwift
import UIKit

class TerrainDemo: DemoMapViewController {
    private let altitudeSlider = UISlider()
    private let hillshadesButton = UIButton(type: .system)
    private let elevationButton = UIButton(type: .system)
    private let slopesButton = UIButton(type: .system)

    // Alps / Chamonix area — great for 3D terrain demo
    private let terrainBBox: GLMapBBox = {
        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(lat: 45.85, lon: 6.75))
        bbox.add(point: GLMapPoint(lat: 46.05, lon: 7.05))
        return bbox
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        map.mapCenter = terrainBBox.center
        map.mapScale = map.mapScale(for: terrainBBox)
        map.isPitchEnabled = true
        map.mapPitch = 45
        map.altitudeScale = 1.5
        map.drawHillshades = true
        map.drawElevationLines = true

        loadDefaultStyle()
        setupControls()

        downloadBBoxData(
            bbox: terrainBBox,
            mapFile: "terrain_map.vmtar",
            eleFile: "terrain_ele.eletar"
        ) { [weak self] in
            self?.map.reloadTiles()
        }
    }

    private func setupControls() {
        let controlsStack = UIStackView()
        controlsStack.axis = .vertical
        controlsStack.spacing = 8
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
        controlsStack.layer.cornerRadius = Theme.cornerRadius
        controlsStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        controlsStack.isLayoutMarginsRelativeArrangement = true

        // Altitude slider
        let sliderLabel = UILabel()
        sliderLabel.text = "Altitude Scale: 1.5"
        sliderLabel.font = Theme.subtitleFont
        sliderLabel.tag = 100

        altitudeSlider.minimumValue = 0.0
        altitudeSlider.maximumValue = 3.0
        altitudeSlider.value = 1.5
        altitudeSlider.addTarget(self, action: #selector(altitudeChanged), for: .valueChanged)

        let sliderRow = UIStackView(arrangedSubviews: [sliderLabel, altitudeSlider])
        sliderRow.axis = .vertical
        sliderRow.spacing = 4

        // Toggle buttons
        hillshadesButton.setTitle("Hillshades: ON", for: .normal)
        hillshadesButton.addTarget(self, action: #selector(toggleHillshades), for: .touchUpInside)

        elevationButton.setTitle("Elevation Lines: ON", for: .normal)
        elevationButton.addTarget(self, action: #selector(toggleElevation), for: .touchUpInside)

        slopesButton.setTitle("Slopes: OFF", for: .normal)
        slopesButton.addTarget(self, action: #selector(toggleSlopes), for: .touchUpInside)

        let buttonsRow = UIStackView(arrangedSubviews: [hillshadesButton, elevationButton, slopesButton])
        buttonsRow.axis = .horizontal
        buttonsRow.spacing = 8
        buttonsRow.distribution = .fillEqually

        controlsStack.addArrangedSubview(sliderRow)
        controlsStack.addArrangedSubview(buttonsRow)

        view.addSubview(controlsStack)
        NSLayoutConstraint.activate([
            controlsStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            controlsStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            controlsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    @objc private func altitudeChanged() {
        let value = altitudeSlider.value
        map.altitudeScale = Float(value)
        if let label = view.viewWithTag(100) as? UILabel {
            label.text = String(format: "Altitude Scale: %.1f", value)
        }
    }

    @objc private func toggleHillshades() {
        map.drawHillshades.toggle()
        hillshadesButton.setTitle("Hillshades: \(map.drawHillshades ? "ON" : "OFF")", for: .normal)
    }

    @objc private func toggleElevation() {
        map.drawElevationLines.toggle()
        elevationButton.setTitle("Elevation Lines: \(map.drawElevationLines ? "ON" : "OFF")", for: .normal)
    }

    @objc private func toggleSlopes() {
        map.drawSlopes.toggle()
        slopesButton.setTitle("Slopes: \(map.drawSlopes ? "ON" : "OFF")", for: .normal)
    }
}
