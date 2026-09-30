import UIKit

/// Screen-space captions only. All geographically anchored objects belong to GLMap.
final class DemoTourOverlay: UIView {
    private let heading = UILabel()
    private let subheading = UILabel()
    private let searchBar = UIView()
    private let searchIcon = UIImageView()
    private let searchText = UILabel()
    private let routeSummary = UILabel()
    private let previewNote = UILabel()
    private let card = UIView()
    private let placeName = UILabel()
    private var phase = -1

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        let accent = DemoTourArtwork.accent
        let ink = DemoTourArtwork.ink
        heading.text = "Amalfi Coast"
        heading.font = .systemFont(ofSize: 30, weight: .bold)
        heading.textColor = ink
        heading.layer.shadowColor = UIColor.white.cgColor
        heading.layer.shadowOpacity = 1
        heading.layer.shadowRadius = 8
        subheading.text = "Preparing your walk…"
        subheading.font = .systemFont(ofSize: 15, weight: .medium)
        subheading.textColor = ink
        subheading.numberOfLines = 0

        panel(searchBar, radius: 20)
        searchIcon.tintColor = accent
        searchIcon.contentMode = .scaleAspectFit
        searchText.font = .systemFont(ofSize: 18, weight: .semibold)
        searchText.textColor = ink
        searchText.adjustsFontSizeToFitWidth = true
        searchBar.addSubview(searchIcon)
        searchBar.addSubview(searchText)

        routeSummary.backgroundColor = accent
        routeSummary.layer.cornerRadius = 15
        routeSummary.clipsToBounds = true
        routeSummary.font = .systemFont(ofSize: 20, weight: .semibold)
        routeSummary.textColor = .white
        routeSummary.textAlignment = .center
        previewNote.text = "Accelerated route preview"
        previewNote.font = .systemFont(ofSize: 11, weight: .medium)
        previewNote.textColor = ink
        previewNote.textAlignment = .center
        previewNote.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        previewNote.layer.cornerRadius = 12
        previewNote.clipsToBounds = true

        panel(card, radius: 24)
        let category = UILabel()
        category.text = "RESTAURANT"
        category.font = .systemFont(ofSize: 11, weight: .bold)
        category.textColor = accent
        placeName.font = .systemFont(ofSize: 23, weight: .bold)
        placeName.textColor = ink
        placeName.adjustsFontSizeToFitWidth = true
        placeName.minimumScaleFactor = 0.65
        let action = UILabel()
        action.text = "A coastal walk  →"
        action.font = .systemFont(ofSize: 17, weight: .semibold)
        action.textColor = .white
        action.textAlignment = .center
        action.backgroundColor = accent
        action.layer.cornerRadius = 15
        action.clipsToBounds = true
        for label in [category, placeName, action] {
            card.addSubview(label)
        }
        for element in [heading, subheading, searchBar, routeSummary, previewNote, card] {
            addSubview(element)
        }
        for element in [heading, subheading, searchBar, searchIcon, searchText, routeSummary, previewNote, card, category, placeName, action] {
            element.translatesAutoresizingMaskIntoConstraints = false
        }
        for element in [searchBar, routeSummary, previewNote, card] {
            element.alpha = 0
        }

        let safe = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: safe.topAnchor, constant: 22),
            heading.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 26),
            heading.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -26),
            subheading.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 4),
            subheading.leadingAnchor.constraint(equalTo: heading.leadingAnchor),
            subheading.trailingAnchor.constraint(equalTo: heading.trailingAnchor),
            searchBar.topAnchor.constraint(equalTo: safe.topAnchor, constant: 18),
            searchBar.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 22),
            searchBar.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -22),
            searchBar.heightAnchor.constraint(equalToConstant: 56),
            searchIcon.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 18),
            searchIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            searchText.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
            searchText.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -16),
            searchText.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            routeSummary.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            routeSummary.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
            routeSummary.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
            routeSummary.heightAnchor.constraint(equalToConstant: 43),
            previewNote.topAnchor.constraint(equalTo: routeSummary.bottomAnchor, constant: 8),
            previewNote.centerXAnchor.constraint(equalTo: safe.centerXAnchor),
            previewNote.widthAnchor.constraint(equalToConstant: 170),
            previewNote.heightAnchor.constraint(equalToConstant: 24),
            card.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -52),
            card.heightAnchor.constraint(equalToConstant: 154),
            category.topAnchor.constraint(equalTo: card.topAnchor, constant: 15),
            category.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            placeName.topAnchor.constraint(equalTo: category.bottomAnchor, constant: 8),
            placeName.leadingAnchor.constraint(equalTo: category.leadingAnchor),
            placeName.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            action.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            action.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            action.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -17),
            action.heightAnchor.constraint(equalToConstant: 46),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    func showPlace(name: String, summary: String) {
        placeName.text = name
        routeSummary.text = summary
        subheading.text = "A place worth the walk"
    }

    func showError(_ message: String) {
        subheading.text = message
    }

    func update(at time: Double) {
        typealias M = DemoTourMotion
        let intro = max(1 - M.ease((time - 3.8) / 0.5), M.ease((time - 24.5) / 1.0))
        let outro = M.outroOpacity(at: time)
        heading.alpha = intro
        subheading.alpha = intro
        searchBar.alpha = M.ease((time - M.searchStart) / 0.45) * outro
        let nextPhase = time < M.routeStart ? 0 : time < M.followStart ? 1 : time < M.arrival ? 2 : 3
        if phase != nextPhase {
            phase = nextPhase
            searchText.text = ["Restaurants nearby", "Your coastal walk", "Walking preview", "You've arrived"][phase]
            searchIcon.image = UIImage(systemName: ["magnifyingglass", "figure.walk", "location.fill", "checkmark.circle.fill"][phase])
        }
        routeSummary.alpha = M.ease((time - M.revealEnd) / 0.5) * outro
        previewNote.alpha = M.ease((time - M.followStart) / 0.4) * (1 - M.ease((time - M.arrival) / 0.4))
        card.alpha = M.ease((time - M.selectionStart) / 0.4) * (1 - M.ease((time - M.overviewStart) / 0.4))
        card.transform = CGAffineTransform(translationX: 0, y: 12 * (1 - card.alpha))
    }

    private func panel(_ view: UIView, radius: CGFloat) {
        view.backgroundColor = .white
        view.layer.cornerRadius = radius
        view.layer.shadowColor = DemoTourArtwork.ink.cgColor
        view.layer.shadowOpacity = 0.14
        view.layer.shadowRadius = 16
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
    }
}
