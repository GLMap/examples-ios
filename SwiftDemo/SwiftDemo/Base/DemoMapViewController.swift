import GLMap
import GLMapSwift
import UIKit

class DemoMapViewController: UIViewController {
    private(set) var map: GLMapView!
    private(set) var stylePath: String = ""
    var usesOnlineTiles: Bool {
        true
    }

    private var previousTileDownloadingAllowed: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        map = GLMapView(frame: view.bounds)
        map.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(map)

        if let path = GLMapManager.shared.resourcesBundle.path(forResource: "DefaultStyle", ofType: "bundle") {
            stylePath = path
            loadStyle()
        }

        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            navigationItem.scrollEdgeAppearance = appearance
            navigationItem.compactScrollEdgeAppearance = appearance
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if previousTileDownloadingAllowed == nil {
            previousTileDownloadingAllowed = GLMapManager.shared.tileDownloadingAllowed
        }
        GLMapManager.shared.tileDownloadingAllowed = usesOnlineTiles
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let previousTileDownloadingAllowed {
            GLMapManager.shared.tileDownloadingAllowed = previousTileDownloadingAllowed
            self.previousTileDownloadingAllowed = nil
        }
        // Keep drawables and weak gesture callbacks for the lifetime of the view.
        // viewWillDisappear can be followed by a cancelled interactive back gesture.
        map.cancelMapAnimations()
    }

    // MARK: - Style helpers

    // defaultValue: true keeps every style option enabled unless explicitly overridden.
    func loadStyle(options: [String: String] = [:]) {
        let parser = GLMapStyleParser(paths: [stylePath, Bundle.main.bundlePath])
        parser.setOptions(options, defaultValue: true)

        do {
            try map.setStyle(parser.parseFromResources())
            map.reloadTiles()
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert("Style Error", message: error.localizedDescription)
            }
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
            if let error = mapManager.add(dataSet, path: path, bbox: bbox).nsError,
               firstError == nil
            {
                firstError = error
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
                    if firstError == nil {
                        firstError = error
                    }
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
        // Resource loading may fail before the view is presented. Keep that error
        // visible rather than trying to present an alert from an offscreen controller.
        guard viewIfLoaded?.window != nil, presentedViewController == nil else {
            navigationItem.prompt = message
            return
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Resource helpers

    func svgPath(_ name: String) -> String? {
        Bundle.main.path(forResource: name, ofType: "svg")
    }
}
