import Foundation

struct DemoScene {
    let caption: String?
    let action: (_ mapVC: DemoModeViewController, _ completion: @escaping () -> Void) -> Void

    init(
        caption: String? = nil,
        action: @escaping (_ mapVC: DemoModeViewController, _ completion: @escaping () -> Void) -> Void
    ) {
        self.caption = caption
        self.action = action
    }
}
