import Foundation

struct DemoScene {
    let name: String
    let duration: TimeInterval
    /// Short feature name shown as a caption while the scene plays (e.g. "3D Terrain").
    let caption: String?
    let action: (_ mapVC: DemoModeViewController, _ completion: @escaping () -> Void) -> Void

    init(
        name: String,
        duration: TimeInterval,
        caption: String? = nil,
        action: @escaping (_ mapVC: DemoModeViewController, _ completion: @escaping () -> Void) -> Void
    ) {
        self.name = name
        self.duration = duration
        self.caption = caption
        self.action = action
    }
}
