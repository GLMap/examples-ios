import GLMap
import GLMapSwift
import UIKit

class TerrainDemo: DemoMapViewController {
    private let altitudeSlider = UISlider()
    private let hillshadesButton = UIButton(type: .system)
    private let elevationButton = UIButton(type: .system)
    private let slopesButton = UIButton(type: .system)
    private let sliderLabel = UILabel()

    /// Alps / Chamonix area — great for 3D terrain demo
    private let terrainBBox: GLMapBBox = {
        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(lat: 45.85, lon: 6.75))
        bbox.add(point: GLMapPoint(lat: 46.05, lon: 7.05))
        return bbox
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        map.mapCenter = terrainBBox.center
        map.mapScale = map.mapScale(for: terrainBBox) * 2 // Start 1 zoom closer
        map.isPitchEnabled = true
        map.mapPitch = 45
        map.altitudeScale = 1.0
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
        sliderLabel.font = Theme.subtitleFont
        altitudeSlider.minimumValue = 0.0
        altitudeSlider.maximumValue = 3.0
        altitudeSlider.value = 1.0
        altitudeSlider.addTarget(self, action: #selector(altitudeChanged), for: .valueChanged)
        updateSliderLabel()

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

    private func updateSliderLabel() {
        sliderLabel.text = String(format: "Altitude Scale: %.1f", altitudeSlider.value)
    }

    @objc private func altitudeChanged() {
        let value = altitudeSlider.value
        map.altitudeScale = Float(value)
        updateSliderLabel()
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
