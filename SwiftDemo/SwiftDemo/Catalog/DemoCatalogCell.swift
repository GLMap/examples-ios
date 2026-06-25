import UIKit

class DemoCatalogCell: UITableViewCell {
    static let reuseID = "DemoCatalogCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let newBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func setupViews() {
        accessoryType = .disclosureIndicator

        iconView.contentMode = .center
        iconView.tintColor = Theme.tintColor
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = Theme.titleFont
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = Theme.subtitleFont
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        newBadge.text = "NEW"
        newBadge.font = Theme.badgeFont
        newBadge.textColor = .white
        newBadge.backgroundColor = Theme.newBadgeColor
        newBadge.textAlignment = .center
        newBadge.layer.cornerRadius = 4
        newBadge.layer.masksToBounds = true
        newBadge.translatesAutoresizingMaskIntoConstraints = false
        newBadge.isHidden = true

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(newBadge)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Theme.cellPadding),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Theme.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Theme.iconSize),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: newBadge.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            newBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            newBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            newBadge.widthAnchor.constraint(equalToConstant: 36),
            newBadge.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    func configure(with demo: DemoDescriptor) {
        iconView.image = UIImage(systemName: demo.icon)
        titleLabel.text = demo.title
        subtitleLabel.text = demo.subtitle
        newBadge.isHidden = !demo.isNew
    }
}
