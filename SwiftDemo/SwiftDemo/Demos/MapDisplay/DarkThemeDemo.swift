import GLMap
import GLMapSwift
import UIKit

class DarkThemeDemo: DemoMapViewController {
    private var isDark = true

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14

        loadStyle(darkTheme: true)

        let toggle = UIBarButtonItem(title: "Light", style: .plain, target: self, action: #selector(toggleTheme))
        navigationItem.rightBarButtonItem = toggle
    }

    @objc private func toggleTheme() {
        isDark.toggle()
        loadStyle(darkTheme: isDark)
        navigationItem.rightBarButtonItem?.title = isDark ? "Light" : "Dark"
    }
}
