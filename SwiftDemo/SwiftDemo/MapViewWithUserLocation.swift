//
//  MapViewControllerBase.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import GLMap
import UIKit

class MapViewWithUserLocation: UIViewController, CLLocationManagerDelegate {
    @IBOutlet var map: GLMapView!
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation() // don't forget to stop updating location
        locationManager.delegate = self

        guard
            let locationImagePath = Bundle.main.path(forResource: "circle_new", ofType: "svg"),
            let locationImage = GLMapVectorImageFactory.shared.image(fromSvg: locationImagePath),
            let movementImagePath = Bundle.main.path(forResource: "arrow_new", ofType: "svg"),
            let movementImage = GLMapVectorImageFactory.shared.image(fromSvg: movementImagePath)
        else {
            assertionFailure("fix location images path")
            return
        }

        map.setUserLocationImage(locationImage, movementImage: movementImage)
        map.showUserLocation = true

        showAccuracyCircle()
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }

    var accuracyCircle: GLMapVectorLayer?
    let accuracyStyle = GLMapVectorCascadeStyle.createStyle("area{width:1px; fill-color:#3D99FA26; color:#3D99FA26;}")
    let CIRCLE_RADIUS: Double = 2048

    func showAccuracyCircle() {
        let CIRCLE_POINTS_COUNT: UInt = 100
        guard let accuracyStyle else { return }

        let vectorLayer = GLMapVectorLayer()
        let outerRings = [GLMapPointArray(count: CIRCLE_POINTS_COUNT, callback: { index in
            let f = 2 * Double.pi * Double(index) / Double(CIRCLE_POINTS_COUNT)
            return GLMapPoint(x: self.CIRCLE_RADIUS * sin(f), y: self.CIRCLE_RADIUS * cos(f))
        })]
        let circle = GLMapVectorObject(polygonOuterRings: outerRings, innerRings: nil)
        vectorLayer.transformMode = .custom
        vectorLayer.position = map.mapCenter
        vectorLayer.setVectorObject(circle, with: accuracyStyle)
        map.add(vectorLayer)

        accuracyCircle = vectorLayer
    }

    var locationAnimation: GLMapAnimation?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationAnimation?.cancel(false)
        locationAnimation = map.animate { anim in
            anim.duration = 1
            anim.transition = .linear
            map.locationManager(manager, didUpdateLocations: locations)

            if let accuracyCircle, let location = locations.last {
                accuracyCircle.position = GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                accuracyCircle.scale = map.makeInternal(fromMeters: location.horizontalAccuracy) / 2048.0
            }
        }
    }
}
