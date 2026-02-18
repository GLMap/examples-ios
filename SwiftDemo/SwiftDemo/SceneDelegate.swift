import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let catalog = DemoCatalogViewController(style: .insetGrouped)
        let nav = UINavigationController(rootViewController: catalog)
        nav.navigationBar.tintColor = Theme.tintColor

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.tintColor = Theme.tintColor
        window.makeKeyAndVisible()
        self.window = window
    }
}
