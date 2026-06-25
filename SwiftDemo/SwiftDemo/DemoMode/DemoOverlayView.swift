import UIKit

class DemoOverlayView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let captionContainer = UIView()
    private let captionLabel = UILabel()
    let exitButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    private func setupViews() {
        isUserInteractionEnabled = true

        titleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        titleLabel.numberOfLines = 1
        // Shrink long titles (e.g. a URL on the end card) so they always fit.
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.4
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 24, weight: .regular)
        subtitleLabel.textColor = UIColor.black.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Caption pill — names the feature currently on screen.
        captionContainer.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        captionContainer.layer.cornerRadius = 16
        captionContainer.alpha = 0
        captionContainer.translatesAutoresizingMaskIntoConstraints = false

        captionLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        captionLabel.textColor = .white
        captionLabel.textAlignment = .center
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        exitButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        exitButton.tintColor = UIColor.white.withAlphaComponent(0.8)
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        exitButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

        captionContainer.addSubview(captionLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(captionContainer)
        addSubview(exitButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),

            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

            captionContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            captionContainer.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            captionContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),

            captionLabel.topAnchor.constraint(equalTo: captionContainer.topAnchor, constant: 8),
            captionLabel.bottomAnchor.constraint(equalTo: captionContainer.bottomAnchor, constant: -8),
            captionLabel.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: captionContainer.trailingAnchor, constant: -16),

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

    /// Shows (or hides, when `text` is nil) the feature caption pill at the top.
    func showCaption(_ text: String?) {
        guard let text else {
            hideCaption()
            return
        }
        if captionLabel.text == text, captionContainer.alpha == 1 {
            return // Same caption already visible — keep it steady across scenes.
        }
        captionLabel.text = text
        UIView.animate(withDuration: 0.4) {
            self.captionContainer.alpha = 1
        }
    }

    func hideCaption() {
        UIView.animate(withDuration: 0.4) {
            self.captionContainer.alpha = 0
        }
    }
}
