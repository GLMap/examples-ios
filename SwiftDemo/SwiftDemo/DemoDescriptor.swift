import UIKit

enum DemoCategory: String, CaseIterable {
    case mapDisplay = "Map Display"
    case camera = "Camera"
    case drawObjects = "Draw Objects"
    case vectorData = "Vector Data"
    case search = "Search"
    case routing = "Routing"
    case offlineData = "Offline Data"

    var icon: String {
        switch self {
        case .mapDisplay: return "map"
        case .camera: return "video"
        case .drawObjects: return "pin.circle"
        case .vectorData: return "point.topleft.down.to.point.bottomright.curvepath"
        case .search: return "magnifyingglass"
        case .routing: return "arrow.triangle.turn.up.right.diamond"
        case .offlineData: return "arrow.down.circle"
        }
    }
}

struct DemoDescriptor {
    let title: String
    let subtitle: String
    let category: DemoCategory
    let icon: String
    let isNew: Bool
    let makeViewController: () -> UIViewController

    init(
        title: String,
        subtitle: String,
        category: DemoCategory,
        icon: String,
        isNew: Bool = false,
        makeViewController: @escaping () -> UIViewController
    ) {
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.icon = icon
        self.isNew = isNew
        self.makeViewController = makeViewController
    }
}
