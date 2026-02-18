import CoreLocation
import GLMap
import GLMapSwift
import UIKit

class UserLocationDemo: DemoMapViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let userLocation = GLMapUserLocation(drawOrder: 100)!
    private var locationAnimation: GLMapAnimation?

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        userLocation.add(toMap: map)
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if userLocation.lastLocation == nil {
            userLocation.locationManager(manager, didUpdateLocations: locations)
            if let loc = locations.last {
                map.mapGeoCenter = GLMapGeoPoint(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
            }
        } else {
            locationAnimation?.cancel(false)
            locationAnimation = map.animate { anim in
                anim.duration = 1
                anim.transition = .linear
                self.userLocation.locationManager(manager, didUpdateLocations: locations)
            }
        }
    }
}
