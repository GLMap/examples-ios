//
//  MapViewControllerBase.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import GLMap
import UIKit

class MapViewControllerBase: UIViewController, CLLocationManagerDelegate {
    @IBOutlet var map: GLMapView!
    private var movementImage, stopImage: GLMapDrawable?
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.startUpdatingLocation() // don't forget to stop updating location
        locationManager.delegate = self
    }

    deinit {
        locationManager.stopUpdatingLocation()
    }

    func display(location: GLMapPoint, bearing: Double, additionalAnimations: (GLMapAnimation) -> Void) {
        let image: GLMapDrawable
        if bearing >= 0 {
            image = movementImage ?? {
                let path = Bundle.main.path(forResource: "arrow_new", ofType: "svg")!
                let img = GLMapVectorImageFactory.shared.image(fromSvg: path)!
                let rv = GLMapImage(drawOrder: 101)
                self.movementImage = rv
                rv.setImage(img, for: map)
                rv.rotatesWithMap = true
                rv.position = location
                rv.offset = CGPoint(x: img.size.width / 2, y: img.size.height / 2)
                map.add(rv)
                return rv
            }()
        } else {
            image = stopImage ?? {
                let path = Bundle.main.path(forResource: "circle_new", ofType: "svg")!
                let img = GLMapVectorImageFactory.shared.image(fromSvg: path)!
                let rv = GLMapImage(drawOrder: 101)
                self.stopImage = rv
                rv.setImage(img, for: map)
                rv.rotatesWithMap = true
                rv.position = location
                rv.offset = CGPoint(x: img.size.width / 2, y: img.size.height / 2)
                map.add(rv)
                return rv
            }()
        }

        stopImage?.hidden = true
        movementImage?.hidden = true
        image.hidden = false

        map.animate { anim in
            anim.duration = 1
            anim.transition = .linear
            image.position = location
            image.angle = Float(-bearing)
            additionalAnimations(anim)
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let pt = GLMapPoint(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        display(location: pt, bearing: location.course, additionalAnimations: { _ in })
    }
}
