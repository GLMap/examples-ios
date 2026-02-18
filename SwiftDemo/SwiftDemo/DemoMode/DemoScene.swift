import Foundation

struct DemoScene {
    let name: String
    let duration: TimeInterval
    let action: (_ mapVC: DemoModeViewController, _ completion: @escaping () -> Void) -> Void
}
