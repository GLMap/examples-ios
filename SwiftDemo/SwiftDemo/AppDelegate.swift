import GLMap
import GLMapSwift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Insert your API key from https://user.globus.software/apps/, or pass GLMAP_API_KEY in the launch environment
        let apiKey = ProcessInfo.processInfo.environment["GLMAP_API_KEY"] ?? "YOUR_API_KEY"
        guard GLMapManager.activate(apiKey: apiKey) else {
            fatalError("GLMap SDK initialization failed")
        }
        return true
    }

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
