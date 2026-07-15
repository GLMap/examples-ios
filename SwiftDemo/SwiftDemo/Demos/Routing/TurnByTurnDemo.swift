import CoreLocation
import GLMap
import GLMapCore
import GLMapSwift
import GLRoute
import UIKit

extension GLManeuverType {
    var svgName: String {
        switch self {
        case .start, .becomes, .continue, .rampStraight, .stayStraight: return "arrow_straight"
        case .startRight: return "arrow_right"
        case .startLeft: return "arrow_left"
        case .slightRight: return "arrow_right_45"
        case .slightLeft: return "arrow_left_45"
        case .rampRight, .exitRight, .stayRight: return "arrow_right_45_plus"
        case .rampLeft, .exitLeft, .stayLeft: return "arrow_left_45_plus"
        case .right: return "arrow_right_90"
        case .left: return "arrow_left_90"
        case .sharpRight: return "arrow_right_135"
        case .sharpLeft: return "arrow_left_135"
        case .uturnRight: return "arrow_right_180"
        case .uturnLeft: return "arrow_left_180"
        case .destination: return "finish"
        case .destinationRight: return "finish_right"
        case .destinationLeft: return "finish_left"
        case .merge: return "arrow_join"
        case .ferryEnter: return "ferry_enter"
        case .ferryExit: return "ferry_exit"
        case .roundaboutEnter: return "roundabout_enter"
        case .roundaboutExit: return "roundabout_exit"
        default: return ""
        }
    }
}

class TurnByTurnDemo: DemoMapViewController, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let userLocation = GLMapUserLocation(drawOrder: 100)!
    private var routeTracker: GLRouteTracker?
    private var routeTrack: GLMapTrack?
    private var requestID: Int64 = 0
    private let routeStyle = GLMapVectorStyle.createStyle("{width:14pt; fill-image:\"track-arrow.svg\";}")!

    // UI
    private let maneuverImage = UIImageView()
    private let maneuverDistance = UILabel()
    private let maneuverStreet = UILabel()
    private let routeInfoLabel = UILabel()
    private var progressAnimation: GLMapAnimation?

    // Route endpoints
    private let startPoint = GLMapGeoPoint(lat: 37.335055, lon: -122.026958)
    private let endPoint = GLMapGeoPoint(lat: 37.405054, lon: -122.156626)

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        loadDefaultStyle()
        setupManeuverUI()

        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        userLocation.add(toMap: map)
        locationManager.delegate = self
        map.mapOrigin = CGPoint(x: 0.5, y: 0.25)

        buildRoute()
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if requestID != 0 { GLRouteRequest.cancel(requestID) }
        requestID = 0
        locationManager.stopUpdatingLocation()
    }

    private func setupManeuverUI() {
        let panel = UIView()
        panel.backgroundColor = UIColor(white: 0.15, alpha: 0.95)
        panel.layer.cornerRadius = Theme.cornerRadius
        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)

        maneuverImage.tintColor = .white
        maneuverImage.contentMode = .scaleAspectFit
        maneuverImage.translatesAutoresizingMaskIntoConstraints = false

        maneuverDistance.textColor = .white
        maneuverDistance.font = .systemFont(ofSize: 28, weight: .bold)
        maneuverDistance.text = "--"
        maneuverDistance.translatesAutoresizingMaskIntoConstraints = false

        maneuverStreet.textColor = .lightGray
        maneuverStreet.font = .systemFont(ofSize: 15)
        maneuverStreet.translatesAutoresizingMaskIntoConstraints = false

        routeInfoLabel.textColor = .lightGray
        routeInfoLabel.font = .systemFont(ofSize: 13)
        routeInfoLabel.textAlignment = .center
        routeInfoLabel.translatesAutoresizingMaskIntoConstraints = false

        panel.addSubview(maneuverImage)
        panel.addSubview(maneuverDistance)
        panel.addSubview(maneuverStreet)
        panel.addSubview(routeInfoLabel)

        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            maneuverImage.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            maneuverImage.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
            maneuverImage.widthAnchor.constraint(equalToConstant: 40),
            maneuverImage.heightAnchor.constraint(equalToConstant: 40),

            maneuverDistance.leadingAnchor.constraint(equalTo: maneuverImage.trailingAnchor, constant: 12),
            maneuverDistance.centerYAnchor.constraint(equalTo: maneuverImage.centerYAnchor),

            maneuverStreet.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            maneuverStreet.topAnchor.constraint(equalTo: maneuverImage.bottomAnchor, constant: 8),
            maneuverStreet.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),

            routeInfoLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            routeInfoLabel.topAnchor.constraint(equalTo: maneuverStreet.bottomAnchor, constant: 4),
            routeInfoLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            routeInfoLabel.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -12),
        ])
    }

    private func buildRoute() {
        let request = GLRouteRequest()
        request.setAutoWithOptions(CostingOptionsAuto())
        request.locale = "en-US"
        request.unitSystem = .international
        request.add(GLRoutePoint(pt: startPoint, heading: .nan, type: .break))
        request.add(GLRoutePoint(pt: endPoint, heading: .nan, type: .break))

        requestID = request.startOnline { [weak self] route, error in
            guard let self, requestID != 0 else { return }
            requestID = 0
            if let route {
                displayRoute(route)
                routeTracker = GLRouteTracker(data: route)
                routeTracker?.currentTargetPointIndex = 1
                locationManager.startUpdatingLocation()
            } else if let error {
                showAlert("Route Error", message: error.localizedDescription)
            }
        }
    }

    private func displayRoute(_ route: GLRoute) {
        if let trackData = route.trackData(with: GLMapColor(red: 50, green: 200, blue: 0, alpha: 200)) {
            let track = GLMapTrack(drawOrder: 99)
            track.progressColor = GLMapColor(red: 128, green: 128, blue: 128, alpha: 200)
            track.setData(trackData, style: routeStyle)
            map.add(track)
            routeTrack = track
        }

        var bbox = GLMapBBox.empty
        bbox.add(point: GLMapPoint(geoPoint: startPoint))
        bbox.add(point: GLMapPoint(geoPoint: endPoint))
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox) / 2
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation.locationManager(manager, didUpdateLocations: locations)

        guard let location = locations.last, let tracker = routeTracker else { return }

        let geoPt = GLMapGeoPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        let bearing = location.course >= 0 ? Float(location.course) : Float.nan

        let maneuver = tracker.updateLocation(geoPt, userBearing: bearing)

        // Update maneuver UI
        if let maneuver {
            let dist = tracker.distanceToNextManeuver
            maneuverDistance.text = formatDistance(dist)
            maneuverStreet.text = maneuver.shortInstruction
            if let path = svgPath(maneuver.type.svgName) {
                maneuverImage.image = GLMapVectorImageFactory.shared.image(fromSvg: path, withScale: 1.0, andTintColor: .white)
            }
        }

        let remaining = tracker.remainingDistance
        let duration = tracker.remainingDuration
        routeInfoLabel.text = "\(formatDistance(remaining)) remaining  ·  \(formatDuration(duration))"

        // Animate progress
        progressAnimation?.cancel(false)
        progressAnimation = map.animate { anim in
            anim.transition = .linear
            anim.duration = 1
            self.routeTrack?.progressIndex = tracker.progressIndex
        }

        // Follow user position
        let userPt = tracker.onRoute ? tracker.locationOnRoute : GLMapPoint(geoPoint: geoPt)
        map.animate { anim in
            anim.duration = 1
            anim.transition = .linear
            self.map.mapCenter = userPt
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        guard meters.isFinite, meters >= 0 else { return "-- m" }
        if meters < 1000 {
            return "\(Int(round(meters / 10) * 10)) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    private func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "-- min" }
        let mins = Int(seconds / 60)
        if mins < 60 { return "\(mins) min" }
        return "\(mins / 60) h \(mins % 60) min"
    }
}
