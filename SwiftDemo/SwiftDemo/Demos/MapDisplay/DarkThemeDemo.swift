import GLMap
import GLMapSwift
import UIKit

class DarkThemeDemo: DemoMapViewController {
    private var isDark = true

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 45.4371, lon: 12.3326) // Venice
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
