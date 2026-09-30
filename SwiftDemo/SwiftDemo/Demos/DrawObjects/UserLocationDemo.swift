import CoreLocation
import GLMap
import GLMapSwift
import UIKit

class UserLocationDemo: DemoMapViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let userLocation = GLMapUserLocation(drawOrder: 100)!
    private var locationAnimation: GLMapAnimation?
    private var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        map.mapGeoCenter = GLMapGeoPoint(lat: 60.3913, lon: 5.3221) // Bergen
        map.mapZoomLevel = 14
        userLocation.add(toMap: map)
        locationManager.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        updateLocationAuthorization()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        updateLocationAuthorization()
    }

    private func updateLocationAuthorization() {
        guard isVisible else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            navigationItem.prompt = "Waiting for location…"
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
            navigationItem.prompt = "Location unavailable. Check Settings → Privacy → Location Services."
        @unknown default:
            break
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        guard isVisible else { return }
        navigationItem.prompt = error.localizedDescription
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isVisible, let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        navigationItem.prompt = nil
        if userLocation.lastLocation == nil {
            userLocation.locationManager(manager, didUpdateLocations: [location])
            map.mapGeoCenter = GLMapGeoPoint(location: location)
        } else {
            locationAnimation?.cancel(false)
            locationAnimation = map.animate { anim in
                anim.duration = 1
                anim.transition = .linear
                self.userLocation.locationManager(manager, didUpdateLocations: [location])
            }
        }
    }
}
