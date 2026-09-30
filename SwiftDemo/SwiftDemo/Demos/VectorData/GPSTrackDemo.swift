import CoreLocation
import GLMap
import GLMapSwift
import UIKit

class GPSTrackDemo: DemoMapViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var trackData: GLMapTrackData?
    private let track = GLMapTrack(drawOrder: 2)
    private let trackStyle = GLMapVectorStyle.createStyle("{width:5pt;}")!
    private let userLocation = GLMapUserLocation(drawOrder: 100)!
    private var locationAnimation: GLMapAnimation?
    private var headingAnimation: GLMapAnimation?
    private var isFirstLocation = true
    private var isVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        map.mapGeoCenter = GLMapGeoPoint(lat: 43.3183, lon: -1.9812) // San Sebastián
        map.mapZoomLevel = 15
        map.isRotateEnabled = true
        map.add(track)
        userLocation.add(toMap: map)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
        locationManager.stopUpdatingHeading()
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
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
        case .denied, .restricted:
            locationManager.stopUpdatingLocation()
            locationManager.stopUpdatingHeading()
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
        guard isVisible else { return }
        let locations = locations.filter { $0.horizontalAccuracy >= 0 }
        guard let location = locations.last else { return }
        navigationItem.prompt = nil
        for location in locations {
            let mapPoint = GLMapPoint(geoPoint: GLMapGeoPoint(location: location))
            var trackPoint = GLTrackPoint(pt: mapPoint, color: GLMapColor(red: 255, green: 255, blue: 0, alpha: 255))
            if let current = trackData {
                trackData = current.appending(trackPoint, startingNewSegment: false)
            } else {
                trackData = GLMapTrackData(points: &trackPoint, count: 1)
            }
        }
        if let trackData {
            track.setData(trackData, style: trackStyle)
        }

        let update = {
            self.userLocation.locationManager(manager, didUpdateLocations: locations)
            self.map.mapGeoCenter = GLMapGeoPoint(location: location)
        }
        if isFirstLocation {
            isFirstLocation = false
            update()
        } else {
            locationAnimation?.cancel(false)
            locationAnimation = map.animate { animation in
                animation.duration = 1
                animation.transition = .linear
                update()
            }
        }
        // Both Core Location bearings and mapAngle are clockwise degrees from north.
        if location.course >= 0 {
            follow(bearing: location.course)
        }
    }

    func locationManager(_: CLLocationManager, didUpdateHeading heading: CLHeading) {
        guard isVisible, (locationManager.location?.course ?? -1) < 0,
              heading.headingAccuracy >= 0, heading.trueHeading >= 0 else { return }
        follow(bearing: heading.trueHeading)
    }

    private func follow(bearing: Double) {
        // Compass updates must not cancel the location marker's interpolation.
        headingAnimation?.cancel(false)
        headingAnimation = map.animate { animation in
            animation.duration = 0.3
            animation.transition = .linear
            self.map.mapAngle = Float(bearing)
        }
    }
}
