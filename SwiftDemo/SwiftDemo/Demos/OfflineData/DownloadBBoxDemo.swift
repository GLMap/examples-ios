import GLMap
import GLMapSwift
import UIKit

class DownloadBBoxDemo: DemoMapViewController {
    private let downloadLabel = UILabel()

    private let demoBBox: GLMapBBox = {
        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(lat: 43.73, lon: 11.20))
        bbox.add(point: GLMapPoint(lat: 43.80, lon: 11.30))
        return bbox
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        map.mapCenter = demoBBox.center
        map.mapScale = map.mapScale(for: demoBBox)
        map.enableClipping(demoBBox, minLevel: 9, maxLevel: 16)

        downloadLabel.font = .systemFont(ofSize: 14)
        downloadLabel.textColor = .white
        downloadLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        downloadLabel.textAlignment = .center
        downloadLabel.layer.cornerRadius = 8
        downloadLabel.layer.masksToBounds = true
        downloadLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(downloadLabel)

        NSLayoutConstraint.activate([
            downloadLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            downloadLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            downloadLabel.heightAnchor.constraint(equalToConstant: 36),
        ])

        startDownload()
    }

    private func startDownload() {
        downloadLabel.text = "Downloading map + nav + elevation..."

        downloadBBoxData(
            bbox: demoBBox,
            files: [
                (.map, "bbox_map.vmtar"),
                (.navigation, "bbox_nav.navtar"),
                (.elevation, "bbox_ele.eletar"),
            ]
        ) { [weak self] error in
            guard let self else { return }
            if let error {
                downloadLabel.text = "Download failed"
                showAlert("Download Error", message: error.localizedDescription)
                return
            }
            map.drawElevationLines = true
            map.drawHillshades = true
            map.reloadTiles()
            downloadLabel.text = "All data downloaded"
            UIView.animate(withDuration: 1, delay: 2) {
                self.downloadLabel.alpha = 0
            }
        }
    }
}
