//
//  RouteTrackerViewController.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 5/29/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import GLMap
import GLMapCore
import GLMapSwift
import GLRoute
import UIKit

extension GLManeuverType {
    var imageName: String {
        switch self {
        case .start, .becomes, .continue, .rampStraight, .stayStraight: return "arrow_straight"
        case .startRight: return "arrow_rigth"
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
        // TODO:
        case .none, .transit, .transitTransfer, .transitRemainOn, .transitConnectionStart,
             .transitConnectionTransfer, .transitConnectionDestination, .postTransitConnectionDestination, .mergeRight, .mergeLeft, .elevatorEnter,
             .stepsEnter, .escalatorEnter, .buildingEnter, .buildingExit:
            return ""
        }
    }
}

private let colors: [GLMapColor] = [
    GLMapColor(red: 115, green: 204, blue: 41, alpha: 230), // green
    GLMapColor(red: 236, green: 237, blue: 26, alpha: 230), // yellow
    GLMapColor(red: 250, green: 72, blue: 102, alpha: 230), // red
]

private func mix(from: UInt8, to: UInt8, k: Double) -> UInt8 {
    var rv = Double(from) * (1.0 - k)
    rv += Double(to) * k
    return UInt8(rv)
}

private func mix(from: GLMapColor, to: GLMapColor, k: Double) -> GLMapColor {
    return GLMapColor(red: mix(from: from.red, to: to.red, k: k),
                      green: mix(from: from.green, to: to.green, k: k),
                      blue: mix(from: from.blue, to: to.blue, k: k),
                      alpha: mix(from: from.alpha, to: to.alpha, k: k))
}

private func colorForAltitude(min: Double, delta: Double, val: Double) -> GLMapColor {
    var k = (val - min) / delta
    if !k.isFinite {
        k = 0
    }
    return val < 0.5 ?
        mix(from: colors[0], to: colors[1], k: k * 2) :
        mix(from: colors[1], to: colors[2], k: (k - 0.5) * 2)
}

private func svgFullPath(_ name: String) -> String {
    return Bundle.main.path(forResource: name, ofType: "svg")!
}

private let ReRoute_MinTimeBetween = 10.0
private let ReRoute_DistanceFromRoute = 100.0
private let ReRoute_DistanceToLastPoint = 100.0
private let ReRoute_MaxAccuracy = 50.0

class RouteTrackerViewController: MapViewWithUserLocation, RouteHelperDelegate {
    private enum ManeuverStatus: UInt8 {
        case initial, postTransition, preTransition, transition, final
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private var route: Route
    private var routeTracker: GLRouteTracker
    private var helper: RouteHelper

    private var targetPoint: RoutePoint { didSet { updateCurrentTarget() } }
    private var originalParams: RouteParams { didSet { updateTargetPoints() } }

    private var routePoints = [String: GLMapImage]()
    private var routeTrackData: GLMapTrackData?
    private var routeTrack: GLMapTrack?
    private let routeStyle = GLMapVectorStyle.createStyle("{width:14pt; fill-image:\"track-arrow.svg\";}")!

    private var resumeTracking = false, wasOnRoute = false
    private var pauseTracking = false { didSet { updateStopButton() } }

    private var menuRoutePoint: RoutePoint?
    private var localizableStrings = [String: String]()
    private var lastRequestTime: TimeInterval = 0
    private var prevTextToSay: String?
    private var prevManeuver, nextManeuver: GLRouteManeuver?
    private var maneuverStatus = ManeuverStatus.initial { didSet { updateStopButton() } }

    private var lastLocation: CLLocation?

    @IBOutlet private var btnStop, btnPrevPoint, btnNextPoint: UIButton!
    @IBOutlet private var routeETA, routeLength, routeDuration: UILabel!
    @IBOutlet private var lblRoutingSpeed, lblRoutingSpeedUnits: UILabel!
    @IBOutlet private var imgRouteSpeedBackground, imgPoint: UIImageView!
    @IBOutlet private var lblManeuverStreet, lblManeuverDistance, lblTargetPointName: UILabel!
    @IBOutlet private var imgManeuver, imgSecondaryManeuver: UIImageView!
    @IBOutlet private var routeUpdateIndicator: UIActivityIndicatorView!

    private var observers = [NSKeyValueObservation]()

    override var canBecomeFirstResponder: Bool { return true }
    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) has not been implemented") }

    init(_ route: Route) {
        originalParams = route.params
        self.route = route
        routeTracker = GLRouteTracker(data: route.route)

        if route.params.startPoint.isCurrentLocation {
            targetPoint = route.params.points[1]
        } else {
            targetPoint = route.params.startPoint
        }

        helper = RouteHelper(params: route.params)
        super.init(nibName: nil, bundle: nil)
        helper.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        routeChanged(.success(result: route))
        routeParamsChanged()
        routeIsUpdatingChanged()
        updateCurrentTarget()
        updateImages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        map.mapOrigin = CGPoint(x: 0.5, y: 0.25)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        helper.cancel()
    }

    @objc func willEnterForeground() {
        if let lastLocation {
            locationChanged(lastLocation)
        }
    }

    private func updateRoute(newPoint: RoutePoint? = nil, deletePoint: RoutePoint? = nil) {
        guard let index = originalParams.points.firstIndex(of: targetPoint), let curLocation = lastLocation else { return }

        if let deletePoint {
            originalParams = originalParams.deleting(deletePoint)
            display(routeParams: originalParams)
        }

        let cur = GLMapGeoPoint(lat: curLocation.coordinate.latitude, lon: curLocation.coordinate.longitude)
        var newPoints = [RoutePoint(pt: GLRoutePoint(pt: cur, heading: curLocation.course, originalIndex: 0, type: .break),
                                    isCurrentLocation: true)]
        if let newPoint {
            newPoints.append(newPoint)
            originalParams = originalParams.adding(newPoint)
            display(routeParams: originalParams)
        }
        for pt in originalParams.points[index...] where !pt.isCurrentLocation && newPoints.last != pt {
            newPoints.append(pt)
        }
        helper.update(RouteParams(points: newPoints, mode: originalParams.mode))
    }

    // MARK: Route point image

    private func image(for pt: RoutePoint) -> UIImage? {
        if pt.isCurrentLocation {
            return nil
        }
        if pt.index == 0 {
            return GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath("nav_bottom_start"))
        } else if pt === originalParams.finishPoint {
            return GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath("nav_bottom_finish"))
        }
        return drawMiddlePoint(bgName: svgFullPath("nav_bottom_start"), index: "\(pt.index)", textSize: 15)
    }

    private func mapImage(key: String) -> UIImage {
        if key == "nav_map_start" || key == "nav_map_finish" {
            return GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath(key))!
        } else {
            return drawMiddlePoint(bgName: "nav_map_start", index: key, textSize: 20)
        }
    }

    private func drawableKey(for pt: RoutePoint, finishPoint: RoutePoint?) -> String? {
        if pt.isCurrentLocation {
            return nil
        }
        if pt.index == 0 {
            return "nav_map_start"
        } else if pt === finishPoint {
            return "nav_map_finish"
        }
        return "\(pt.index)"
    }

    private func drawMiddlePoint(bgName: String, index: String, textSize: CGFloat) -> UIImage {
        let bg = GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath(bgName), withScale: 1.0)!
        UIGraphicsBeginImageContextWithOptions(bg.size, false, bg.scale)
        bg.draw(at: .zero)
        let str = NSAttributedString(string: index,
                                     attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: textSize, weight: .semibold),
                                                  NSAttributedString.Key.foregroundColor: UIColor.white])
        let size = str.size()
        str.draw(at: CGPoint(x: round((bg.size.width - size.width) / 2), y: floor((bg.size.height - size.height) / 2)))
        let rv = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return rv
    }

    // MARK: Update functions

    func updateImages() {
        let factory = GLMapVectorImageFactory.shared
        let actionButtonsColor = GLMapColor(uiColor: #colorLiteral(red: 0.3333333333, green: 0.3333333333, blue: 0.3333333333, alpha: 1))

        imgRouteSpeedBackground.image = factory.image(fromSvg: svgFullPath("gray_circle"), withScale: 1)
        btnPrevPoint.setImage(factory.image(fromSvg: svgFullPath("nav_point_prev"),
                                            withScale: 1, andTintColor: actionButtonsColor), for: .normal)
        btnNextPoint.setImage(factory.image(fromSvg: svgFullPath("nav_point_next"),
                                            withScale: 1, andTintColor: actionButtonsColor), for: .normal)

        btnStop.setBackgroundImage(factory.image(fromSvg: svgFullPath("route_button")), for: .normal)
        btnStop.setBackgroundImage(factory.image(fromSvg: svgFullPath("route_button_act")), for: .highlighted)

        updateStopButton()
    }

    func display(routeParams: RouteParams?) {
        var oldPoints = routePoints
        routePoints.removeAll()
        if let params = routeParams {
            let finishPoint = params.finishPoint
            for pt in params.points {
                guard let key = drawableKey(for: pt, finishPoint: finishPoint) else { continue }
                if routePoints[key] != nil {
                    continue
                }
                let drawable: GLMapImage
                if let tmp = oldPoints.removeValue(forKey: key) {
                    drawable = tmp
                } else {
                    drawable = GLMapImage(drawOrder: 100)
                    let image = mapImage(key: key)
                    drawable.setImage(image, for: map)
                    drawable.offset = CGPoint(x: image.size.width / 2, y: image.size.height / 2)
                    map.add(drawable)
                }
                drawable.position = GLMapPoint(geoPoint: pt.location)
                routePoints[key] = drawable
            }
        }
        for (_, drawable) in oldPoints {
            map.remove(drawable)
        }
    }

    func display(route: GLRoute?) {
        if let route {
            if let heightData = route.heightData {
                let min = heightData.min
                let delta = heightData.max - min
                routeTrackData = route.trackData(callback: { i in
                    colorForAltitude(min: min, delta: delta, val: heightData.height(at: i))
                })
            } else {
                routeTrackData = route.trackData(with: GLMapColor(uiColor: .blue))
            }
        } else {
            routeTrackData = nil
        }

        if let trackData = routeTrackData {
            if let routeTrack {
                routeTrack.setTrackData(trackData, style: routeStyle)
                routeTrack.progressIndex = 0
            } else {
                let routeTrack = GLMapTrack(drawOrder: 99)
                routeTrack.progressColor = GLMapColor(red: 128, green: 128, blue: 128, alpha: 200)
                routeTrack.setTrackData(trackData, style: routeStyle)
                map.add(routeTrack)
                self.routeTrack = routeTrack
            }
        } else if let routeTrack {
            map.remove(routeTrack)
            self.routeTrack = nil
        }
    }

    private func updateTargetPoints() {
        let points = route.params.points
        var index = Int(routeTracker.currentTargetPointIndex)
        while points[index].isCurrentLocation {
            if index + 1 >= points.count {
                break
            }
            index += 1
        }
        if points[index] != targetPoint {
            targetPoint = points[index]
        }
    }

    private func updateCurrentTarget() {
        lblTargetPointName.text = targetPoint.name
        imgPoint.image = image(for: targetPoint)
    }

    private func updateStopButton() {
        let img: UIImage?
        if pauseTracking {
            img = GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath("icon_gps_ipad"),
                                                       withScale: 1.0, andTintColor: .white)
        } else if maneuverStatus == .final {
            img = GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath("route_finish"),
                                                       withScale: 1.0, andTintColor: .white)
        } else {
            img = GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath("route_pause"),
                                                       withScale: 1.0, andTintColor: .white)
        }
        btnStop.setImage(img, for: .normal)
    }

    private func showManeuverImage(_ maneuverType: GLManeuverType) {
        imgManeuver.image = GLMapVectorImageFactory.shared.image(fromSvg: svgFullPath(maneuverType.imageName),
                                                                 withScale: 1.0, andTintColor: .white)
    }

    private func showSecondaryManeuverImage(_ maneuver: GLRouteManeuver?) {
        if let maneuver {
            imgSecondaryManeuver.image = GLMapVectorImageFactory.shared.image(fromSvg: maneuver.type.imageName,
                                                                              withScale: 1.0, andTintColor: .white)
            if imgSecondaryManeuver.alpha != 1 {
                UIView.animate(withDuration: 0.5) { self.imgSecondaryManeuver.alpha = 1 }
            }
        } else if imgSecondaryManeuver.alpha != 0 {
            UIView.animate(withDuration: 0.5) { self.imgSecondaryManeuver.alpha = 0 }
        }
    }

    // MARK: RouteHelperDelegate

    func routeParamsChanged() {}

    func routeChanged(_ result: BuildRouteTask.Result?) {
        switch result {
        case let .success(result):
            route = result
            routeTracker = GLRouteTracker(data: route.route)
            if route.params.startPoint.isCurrentLocation { // Skip current location
                routeTracker.currentTargetPointIndex = 1
            }
            display(route: route.route)
            display(routeParams: originalParams)
            maneuverStatus = .initial // Сбросим чтобы отработала логика стартовой фразы
            localizableStrings.removeAll()
            if let lastLocation {
                locationChanged(lastLocation)
            }
        default:
            break
        }
    }

    func routeIsUpdatingChanged() {
        if helper.isUpdating {
            routeUpdateIndicator.startAnimating()
        } else {
            routeUpdateIndicator.stopAnimating()
        }
    }

    // MARK: User actions

    /* override func tap(onMap location: CGPoint) {
     guard let mapView else { return }
     let mapPt = mapView.makeMapPoint(fromDisplay: location)

     // Проверим тап по точке роута
     if originalParams.notPlaceholderPointsCount > 2, let pt = originalParams.findRoutePoint(mapPt, mapView: mapView) {
     menuRoutePoint = pt
     let imgDelete = GLMapVectorImageFactory.shared.image(fromSvgpb: "Delete", tintColor: .white)!
     let deletePointItem = UIMenuItem(title: Loc("_Loc_DeletePoint"), action: #selector(deleteRoutePoint), image: imgDelete)
     showMenu([deletePointItem], screenPoint: location, yOffset: -3)
     return
     }
     }

     override func longTap(onMap screenPoint: CGPoint) {
     let routeVia = GLMapVectorImageFactory.shared.image(fromSvgpb: "Route_Via", tintColor: .white)!
     let items = [UIMenuItem(title: "MiddlePoint", action: #selector(menuAddMiddlePoint), image: routeVia)]
     showLongTapMenu(screenPoint: screenPoint, addItems: items)
     }

     override func mapDidMoved() {
     pauseTracking = true
     }

     @objc private func deleteRoutePoint() {
     if let point = menuRoutePoint {
     updateRoute(deletePoint: point)
     }
     }

     @objc private func menuAddMiddlePoint() {
     updateRoute(newPoint: RoutePoint(position: menuPoint, name: nil))
     } */

    @IBAction private func nextTargetPoint(_: Any) {
        let points = originalParams.points
        if var index = points.firstIndex(of: targetPoint) {
            var newPoint = targetPoint
            repeat {
                index += 1
                if index >= points.count {
                    index = 0
                }
                newPoint = points[index]
            } while newPoint.isCurrentLocation && newPoint != targetPoint
            if newPoint != targetPoint {
                targetPoint = newPoint
                updateRoute()
            }
        }
    }

    @IBAction private func prevTargetPoint(_: Any) {
        let points = originalParams.points
        if var index = points.firstIndex(of: targetPoint) {
            var newPoint = targetPoint
            repeat {
                if index == 0 {
                    index = points.count - 1
                } else {
                    index -= 1
                }
                newPoint = points[index]
            } while newPoint.isCurrentLocation && newPoint != targetPoint
            if newPoint != targetPoint {
                targetPoint = newPoint
                updateRoute()
            }
        }
    }

    @IBAction private func stopTap(_ sender: UIButton) {
        if pauseTracking {
            pauseTracking = false
            resumeTracking = true
            if let lastLocation {
                locationChanged(lastLocation)
            }
        } else {
            if maneuverStatus == .final {
                navigationController?.popViewController(animated: true)
            } else {
                let vc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                vc.popoverPresentationController?.sourceView = sender
                vc.popoverPresentationController?.sourceRect = sender.bounds
                vc.addAction(UIAlertAction(title: "Stop Route", style: .default, handler: { [weak self] _ in
                    guard let self else { return }
                    self.navigationController?.popViewController(animated: true)
                }))
                vc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(vc, animated: true)
            }
        }
    }

    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        super.locationManager(manager, didUpdateLocations: locations)

        if let location = locations.last {
            lastLocation = location
            locationChanged(location)
        }
    }

    var progressAnimation: GLMapAnimation?

    func locationChanged(_ location: CLLocation) {
        let userGeoLocation = GLMapGeoPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        var userLocation = GLMapPoint(geoPoint: userGeoLocation)
        var userBearing = location.course >= 0 ? Float(location.course) : Float.nan
        let curSpeed = location.speed >= 0 ? location.speed : 0

        let fmt = Formatters.si
        (lblRoutingSpeed.text, lblRoutingSpeedUnits.text) = fmt.format(speed: curSpeed)
        let speedInKmh = (curSpeed.isFinite && curSpeed > 0) ? (curSpeed * 3.6) : 0
        let maneuver = routeTracker.updateLocation(userGeoLocation, userBearing: userBearing)
        updateTargetPoints()

        let durationLeft = routeTracker.remainingDuration
        routeETA.text = fmt.format(timestamp: NSDate.timeIntervalSinceReferenceDate + durationLeft)
        routeDuration.text = fmt.format(duration: durationLeft)
        routeLength.text = fmt.format(distance: routeTracker.remainingDistance)

        let routeData = route.route
        let distanceToNextManeuver = routeTracker.distanceToNextManeuver
        let nextManeuver = maneuver != nil ? routeData.getNextManeuver(maneuver!) : nil
        let maneuverType = maneuver?.type ?? .none

        lblManeuverStreet.text = maneuver?.shortInstruction
        lblManeuverDistance.text = fmt.format(distance: distanceToNextManeuver)
        showManeuverImage(maneuverType)
        showSecondaryManeuverImage((distanceToNextManeuver < 300 && (maneuver?.length ?? 0) < 150) ? nextManeuver : nil)

        if routeTracker.onRoute {
            userLocation = routeTracker.locationOnRoute
            userBearing = routeTracker.bearingAngleOnRoute
        } else {
            let curTime = NSDate.timeIntervalSinceReferenceDate
            if abs(curTime - lastRequestTime) > ReRoute_MinTimeBetween,
               !helper.isUpdating,
               routeTracker.distanceToLastPoint > ReRoute_DistanceToLastPoint,
               routeTracker.distanceFromRoute > ReRoute_DistanceFromRoute,
               location.horizontalAccuracy < ReRoute_MaxAccuracy
            {
                lastRequestTime = curTime
                updateRoute()
            }
        }

        if speedInKmh < 0 {
            userBearing = Float.nan
        }

        progressAnimation?.cancel(false)
        progressAnimation = map.animate { anim in
            anim.transition = .linear
            anim.duration = 1
            self.routeTrack?.progressIndex = self.routeTracker.progressIndex
        }

        if maneuverStatus != .final {
            var textToSay: String?
            if let maneuver {
                if prevManeuver != maneuver {
                    if maneuverStatus != .postTransition {
                        if maneuverStatus == .initial {
                            textToSay = routeData.getPreviousManeuver(maneuver)?.verbalPreTransitionInstruction
                        } else {
                            textToSay = prevManeuver?.verbalPostTransitionInstruction
                        }
                        maneuverStatus = .postTransition
                    }
                    prevManeuver = maneuver
                }
                let preTransitionGate = speedInKmh <= 90 ? 300.0 : 1000.0
                if distanceToNextManeuver <= preTransitionGate {
                    if maneuverStatus != .preTransition, maneuverStatus != .transition {
                        textToSay = maneuver.verbalPreTransitionInstruction
                        maneuverStatus = .preTransition
                    } else {
                        textToSay = nil
                    }
                }

                if distanceToNextManeuver < 100 {
                    if maneuverStatus != .transition {
                        textToSay = maneuver.verbalTransitionInstruction
                        maneuverStatus = .transition
                    } else {
                        textToSay = nil
                    }
                }
            }

            if routeTracker.distanceToLastPoint < 50, curSpeed == 0 {
                maneuverStatus = .final
                if let lastManeuver = routeData.allManeuvers.last, let instruction = lastManeuver.verbalPreTransitionInstruction, instruction.count > 0 {
                    textToSay = instruction
                }
            }
            if textToSay != nil {
                NSLog("Say: '\(textToSay ?? "")'")
            }
        }

        if let maneuver = maneuver, !pauseTracking {
            let mapLevel: Double
            if route.params.mode != .straight {
                let minLevel: Double
                if speedInKmh <= 0 {
                    minLevel = 17
                } else if speedInKmh <= 30 {
                    minLevel = 17 - 0.5 * (speedInKmh - 0) / 30.0
                } else if speedInKmh <= 60 {
                    minLevel = 16.5 - 1.0 * (speedInKmh - 30) / 30.0
                } else if speedInKmh <= 120 {
                    minLevel = 15.5 - 1.0 * (speedInKmh - 60) / 60.0
                } else {
                    minLevel = 14.5
                }
                let maxLevel = minLevel + 1

                var bbox = GLMapBBox.empty.adding(maneuver.startPoint)
                bbox.add(point: userLocation)
                mapLevel = min(max(minLevel, log2(map.mapScale(for: bbox))), maxLevel)
            } else {
                mapLevel = map.mapZoomLevel
            }

            if resumeTracking {
                resumeTracking = false
                map.animate { animation in animation.fly(to: userLocation) }
            } else {
                map.animate { animation in
                    animation.duration = 1
                    animation.transition = .linear
                    animation.continueFlyTo = true
                    map.mapCenter = userLocation
                }
            }

            let setNewAngle = userBearing.isFinite && (abs(map.mapAngle - userBearing) > 2)
            let setNewZoom = abs(map.mapZoomLevel - mapLevel) > 0.2
            if setNewAngle || setNewZoom {
                map.animate { _ in
                    if setNewAngle {
                        map.mapAngle = userBearing
                    }
                    if setNewZoom {
                        map.mapZoomLevel = mapLevel
                    }
                }
            }
        }
    }
}
