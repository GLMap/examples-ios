import GLMap
import GLMapSwift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        GLMapManager.activate(apiKey: "")

        let catalog = DemoCatalogViewController(style: .insetGrouped)
        let nav = UINavigationController(rootViewController: catalog)
        nav.navigationBar.tintColor = Theme.tintColor

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.tintColor = Theme.tintColor
        window?.makeKeyAndVisible()

        return true
    }
}
