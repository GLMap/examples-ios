//
//  ImageGroup.swift
//  GLMap
//
//  Created by Arkadiy Tolkun on 8/30/17.
//  Copyright © 2017 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLMap
import GLMapSwift

struct Pin {
    let position: GLMapPoint
    let imageID: UInt32
    init(position: GLMapPoint, imageID: UInt32) {
        self.position = position
        self.imageID = imageID
    }

    static func == (lhs: Pin, rhs: Pin) -> Bool {
        return lhs.position == rhs.position && lhs.imageID == rhs.imageID
    }
}

class ImageGroup: GLMapImageGroupDataSource {
    let lock: NSRecursiveLock
    let vairants: Array<UIImage>
    var pins: Array<Pin>

    init() {
        lock = NSRecursiveLock()
        vairants = [
            UIImage(named: "pin1.png")!,
            UIImage(named: "pin2.png")!,
            UIImage(named: "pin3.png")!,
        ]
        pins = []
    }

    public func startUpdate() {
        lock.lock()
    }

    public func getVariantsCount() -> Int {
        return vairants.count
    }

    public func getVariant(_ index: Int, offset: UnsafeMutablePointer<CGPoint>) -> UIImage {
        let rv = vairants[index]
        offset.pointee = CGPoint(x: rv.size.width / 2, y: 0)
        return rv
    }

    public func getImagesCount() -> Int {
        return pins.count
    }

    public func getImageInfo(_ index: Int, vairiant variant: UnsafeMutablePointer<UInt32>, position: UnsafeMutablePointer<GLMapPoint>) {
        variant.pointee = pins[index].imageID
        position.pointee = pins[index].position
    }

    public func endUpdate() {
        lock.unlock()
    }

    public func count() -> Int {
        lock.lock()
        let rv = pins.count
        lock.unlock()
        return rv
    }

    public func append(_ pin: Pin) {
        lock.lock()
        pins.append(pin)
        lock.unlock()
    }

    public func remove(_ pin: Pin) {
        lock.lock()
        if let index = pins.firstIndex(where: { $0 == pin }) {
            pins.remove(at: index)
        }
        lock.unlock()
    }

    public func findPin(point: CGPoint, mapView: GLMapView) -> Pin? {
        var rv: Pin?
        lock.lock()

        let rect = CGRect(x: -20, y: -20, width: 40, height: 40).offsetBy(dx: point.x, dy: point.y)
        for pin in pins {
            if rect.contains(mapView.makeDisplayPoint(from: pin.position)) {
                rv = pin
                break
            }
        }
        lock.unlock()
        return rv
    }
}
