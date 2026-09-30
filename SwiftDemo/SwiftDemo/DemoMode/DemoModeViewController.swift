import GLMap
import GLMapSwift
import UIKit

/// The catalog's Demo Mode: one continuous map → search → walking-route story.
final class DemoModeViewController: DemoMapViewController {
    private let overlay = UIView()
    private var tour: DemoTour?
    private var previousIdleTimerDisabled: Bool?

    override func viewDidLoad() {
        super.viewDidLoad()
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeDemo))
        tap.cancelsTouchesInView = false
        overlay.addGestureRecognizer(tap)

        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.tintColor = UIColor.black.withAlphaComponent(0.65)
        close.accessibilityLabel = "Close demo"
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(closeDemo), for: .touchUpInside)
        overlay.addSubview(close)
        NSLayoutConstraint.activate([
            close.leadingAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.leadingAnchor, constant: 14),
            close.bottomAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            close.widthAnchor.constraint(equalToConstant: 44),
            close.heightAnchor.constraint(equalToConstant: 44),
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(pauseTour), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeTour), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard tour == nil else { return }
        previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        startTour()
    }

    private func startTour() {
        tour?.stop()
        let newTour = DemoTour(map: map, host: overlay) { [weak self] message in
            self?.showTourError(message)
        }
        tour = newTour
        newTour.startTour()
    }

    private func showTourError(_ message: String) {
        guard view.window != nil, presentedViewController == nil else { return }
        let alert = UIAlertController(title: "Demo unavailable", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in self?.startTour() })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in self?.closeDemo() })
        present(alert, animated: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tour?.stop()
        tour = nil
        if let previousIdleTimerDisabled {
            UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
            self.previousIdleTimerDisabled = nil
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    @objc private func pauseTour() {
        tour?.pause()
    }

    @objc private func resumeTour() {
        tour?.resume()
    }

    @objc private func closeDemo() {
        dismiss(animated: true)
    }
}
