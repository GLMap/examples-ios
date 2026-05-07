import GLMap
import GLMapSwift
import UIKit

class DemoMapViewController: UIViewController {
    private(set) var map: GLMapView!
    private(set) var stylePath: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        map = GLMapView(frame: view.bounds)
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(map)

        if let path = GLMapManager.shared.resourcesBundle.path(forResource: "DefaultStyle", ofType: "bundle") {
            stylePath = path
            loadDefaultStyle()
        }

        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GLMapManager.shared.tileDownloadingAllowed = false
        map.tapGestureBlock = nil
        map.longPressGestureBlock = nil
    }

    // MARK: - Style helpers

    func loadDefaultStyle() {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        if let style = parser.parseFromResources() {
            map.setStyle(style)
        }
    }

    func loadStyle(darkTheme: Bool = false, carDriving: Bool = false) {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        var options = [String: String]()
        if carDriving { options["Style"] = "CarDriving" }
        if darkTheme { options["Theme"] = "Dark" }
        parser.setOptions(options, defaultValue: false)
        if let style = parser.parseFromResources() {
            map.setStyle(style)
            map.reloadTiles()
        }
    }

    // MARK: - BBox download helpers

    private static let cachesDir: String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]

    func cachedPath(for filename: String) -> String {
        (Self.cachesDir as NSString).appendingPathComponent(filename)
    }

    func downloadBBoxData(
        bbox: GLMapBBox,
        mapFile: String = "demo_map.vmtar",
        navFile: String? = nil,
        eleFile: String? = nil,
        completion: @escaping () -> Void
    ) {
        let manager = FileManager.default
        let mapManager = GLMapManager.shared
        let group = DispatchGroup()

        let mapPath = cachedPath(for: mapFile)
        if manager.fileExists(atPath: mapPath) {
            mapManager.add(.map, path: mapPath, bbox: bbox)
        } else {
            group.enter()
            mapManager.downloadDataSet(.map, path: mapPath, bbox: bbox, progress: { _, _, _ in }) { [weak self] _ in
                mapManager.add(.map, path: mapPath, bbox: bbox)
                self?.map.reloadTiles()
                group.leave()
            }
        }

        if let navFile {
            let navPath = cachedPath(for: navFile)
            if manager.fileExists(atPath: navPath) {
                mapManager.add(.navigation, path: navPath, bbox: bbox)
            } else {
                group.enter()
                mapManager.downloadDataSet(.navigation, path: navPath, bbox: bbox, progress: { _, _, _ in }) { _ in
                    mapManager.add(.navigation, path: navPath, bbox: bbox)
                    group.leave()
                }
            }
        }

        if let eleFile {
            let elePath = cachedPath(for: eleFile)
            if manager.fileExists(atPath: elePath) {
                mapManager.add(.elevation, path: elePath, bbox: bbox)
            } else {
                group.enter()
                mapManager.downloadDataSet(.elevation, path: elePath, bbox: bbox, progress: { _, _, _ in }) { _ in
                    mapManager.add(.elevation, path: elePath, bbox: bbox)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - Alerts

    func showAlert(_ title: String? = nil, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Resource helpers

    func svgPath(_ name: String) -> String? {
        Bundle.main.path(forResource: name, ofType: "svg")
    }
}
