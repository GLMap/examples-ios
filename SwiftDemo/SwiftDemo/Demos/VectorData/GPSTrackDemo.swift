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

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14

        let track = GLMapTrack(drawOrder: 2)
        map.add(track)
        self.track = track

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
        userLocation.locationManager(manager, didUpdateLocations: locations)

        for location in locations {
            let mapPoint = GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            var trackPoint = GLTrackPoint(pt: mapPoint, color: GLMapColor(red: 255, green: 255, blue: 0, alpha: 255))

            if let curData = trackData {
                trackData = GLMapTrackData(data: curData, andNewPoint: trackPoint, startNewSegment: false)
            } else {
                trackData = GLMapTrackData(points: &trackPoint, count: 1)
                map.mapGeoCenter = GLMapGeoPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            }
        }

        if let trackData, let track {
            track.setData(trackData, style: trackStyle)
        }
    }
}
