import CoreLocation
import GLMap
import GLMapSwift
import UIKit

class GPSTrackDemo: DemoMapViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var trackData: GLMapTrackData?
    private var track: GLMapTrack?
    private let trackStyle = GLMapVectorStyle.createStyle("{width:5pt;}")!
    private let userLocation = GLMapUserLocation(drawOrder: 100)!
    private var locationAnimation: GLMapAnimation?
    private var isFirstLocation = true

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 15
        map.isRotateEnabled = true

        let track = GLMapTrack(drawOrder: 2)
        map.add(track)
        self.track = track

        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        userLocation.add(toMap: map)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    deinit {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            let mapPoint = GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            var trackPoint = GLTrackPoint(pt: mapPoint, color: GLMapColor(red: 255, green: 255, blue: 0, alpha: 255))

            if let curData = trackData {
                trackData = GLMapTrackData(data: curData, andNewPoint: trackPoint, startNewSegment: false)
            } else {
                trackData = GLMapTrackData(points: &trackPoint, count: 1)
            }
        }

        if let trackData, let track {
            track.setData(trackData, style: trackStyle)
        }

        guard let location = locations.last else { return }
        let geoCenter = GLMapGeoPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)

        if isFirstLocation {
            isFirstLocation = false
            userLocation.locationManager(manager, didUpdateLocations: locations)
            map.mapGeoCenter = geoCenter
            map.mapZoomLevel = 15
            // Rotate to course if available
            if location.course >= 0 {
                map.mapAngle = Float(-location.course * .pi / 180)
            }
        } else {
            locationAnimation?.cancel(false)
            locationAnimation = map.animate { anim in
                anim.duration = 1
                anim.transition = .linear
                self.userLocation.locationManager(manager, didUpdateLocations: locations)
                self.map.mapGeoCenter = geoCenter
                // Rotate map to match movement direction
                if location.course >= 0 {
                    self.map.mapAngle = Float(-location.course * .pi / 180)
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // If not moving (no course data), rotate to compass heading
        if locationManager.location?.course ?? -1 < 0, newHeading.trueHeading >= 0 {
            locationAnimation?.cancel(false)
            locationAnimation = map.animate { anim in
                anim.duration = 0.3
                anim.transition = .linear
                self.map.mapAngle = Float(-newHeading.trueHeading * .pi / 180)
            }
        }
    }
}
