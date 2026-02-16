//
//  MapViewWithUserLocation.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import GLMap
import UIKit

class MapViewWithUserLocation: UIViewController {
    @IBOutlet var map: GLMapView!
    let locationManager = CLLocationManager()
    var userLocation: GLMapUserLocation?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let userLocation = GLMapUserLocation(drawOrder: 100) else {
            return
        }
        userLocation.add(toMap: map)
        self.userLocation = userLocation
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation() // don't forget to stop updating location
        locationManager.delegate = userLocation
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }
}
