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

    // defaultValue: true enables every style option that isn't overridden — all POI categories,
    // building names, transit, and HideExtraData (which hides the extractor-only debug rules in
    // extra.mapcss). defaultValue: false would instead blank those categories and show the debug labels.
    func loadDefaultStyle() {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        parser.setOptions([:], defaultValue: true)
        if let style = try? parser.parseFromResources() {
            map.setStyle(style)
        }
    }

    func loadStyle(darkTheme: Bool = false, carDriving: Bool = false) {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        var options = [String: String]()
        if carDriving { options["Style"] = "CarDriving" }
        if darkTheme { options["Theme"] = "Dark" }
        parser.setOptions(options, defaultValue: true)
        if let style = try? parser.parseFromResources() {
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
        files: [(dataSet: GLMapInfoDataSet, filename: String)],
        completion: @escaping (Error?) -> Void
    ) {
        let mapManager = GLMapManager.shared
        let group = DispatchGroup()
        var firstError: Error?

        func add(_ dataSet: GLMapInfoDataSet, path: String) {
            let error = mapManager.add(dataSet, path: path, bbox: bbox)
            if !error.isSuccess, firstError == nil {
                firstError = NSError(
                    domain: "GLMap",
                    code: Int(error.rawValue),
                    userInfo: [NSLocalizedDescriptionKey: "Cannot open \(path)"]
                )
            }
        }

        for file in files {
            let path = cachedPath(for: file.filename)
            if FileManager.default.fileExists(atPath: path) {
                add(file.dataSet, path: path)
                continue
            }

            group.enter()
            mapManager.downloadDataSet(file.dataSet, path: path, bbox: bbox, progress: { _, _, _ in }) { error in
                if let error {
                    try? FileManager.default.removeItem(atPath: path)
                    if firstError == nil { firstError = error }
                } else {
                    add(file.dataSet, path: path)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(firstError)
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
