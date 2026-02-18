import UIKit

class DemoOverlayView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    let exitButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        isUserInteractionEnabled = true

        titleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 24, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        exitButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        exitButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(exitButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),

            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            exitButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            exitButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    func showTitle(_ title: String, subtitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        UIView.animate(withDuration: 0.8) {
            self.titleLabel.alpha = 1
            self.subtitleLabel.alpha = subtitle != nil ? 1 : 0
        }
    }

    func hideTitle() {
        UIView.animate(withDuration: 0.5) {
            self.titleLabel.alpha = 0
            self.subtitleLabel.alpha = 0
        }
    }
}
