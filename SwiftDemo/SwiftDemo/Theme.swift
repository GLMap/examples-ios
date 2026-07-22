import UIKit

enum Theme {
    static let tintColor = UIColor(red: 0.13, green: 0.55, blue: 0.96, alpha: 1.0)
    static let backgroundColor = UIColor.systemGroupedBackground
    static let cardBackground = UIColor.secondarySystemGroupedBackground
    static let newBadgeColor = UIColor.systemOrange

    static let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let subtitleFont = UIFont.systemFont(ofSize: 13, weight: .regular)
    static let badgeFont = UIFont.systemFont(ofSize: 11, weight: .bold)
    static let headerFont = UIFont.systemFont(ofSize: 13, weight: .semibold)

    static let cornerRadius: CGFloat = 12
    static let cellPadding: CGFloat = 16
    static let iconSize: CGFloat = 32
}
