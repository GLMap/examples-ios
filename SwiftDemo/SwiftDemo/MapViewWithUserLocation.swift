//
//  MapViewWithUserLocation.swift
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
    private let userLocation = GLMapUserLocation(drawOrder: 100)!

    override func viewDidLoad() {
        super.viewDidLoad()
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        userLocation.add(toMap: map)
        locationManager.startUpdatingLocation() // don't forget to stop updating location
        locationManager.delegate = self
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }

    var locationAnimation: GLMapAnimation?
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Do first location update without animation
        if userLocation.lastLocation == nil {
            userLocation.locationManager(manager, didUpdateLocations: locations)
        } else {
            locationAnimation?.cancel(false)
            locationAnimation = map.animate { anim in
                anim.duration = 1
                anim.transition = .linear
                userLocation.locationManager(manager, didUpdateLocations: locations)
            }
        }
    }
}
