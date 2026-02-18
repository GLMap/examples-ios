import GLMap
import GLMapSwift
import UIKit

private struct Pin {
    let position: GLMapPoint
    let imageID: UInt32

    static func == (lhs: Pin, rhs: Pin) -> Bool {
        lhs.position == rhs.position && lhs.imageID == rhs.imageID
    }
}

private class PinGroup: GLMapImageGroupDataSource {
    let lock = NSRecursiveLock()
    let variants: [UIImage] = [
        UIImage(named: "pin1.png")!,
        UIImage(named: "pin2.png")!,
        UIImage(named: "pin3.png")!,
    ]
    var pins: [Pin] = []

    func startUpdate() { lock.lock() }
    func endUpdate() { lock.unlock() }

    func getVariantsCount() -> Int { variants.count }

    func getVariant(_ index: Int, offset: UnsafeMutablePointer<CGPoint>) -> UIImage {
        let img = variants[index]
        offset.pointee = CGPoint(x: img.size.width / 2, y: 0)
        return img
    }

    func getImagesCount() -> Int { pins.count }

    func getImageInfo(_ index: Int, variant: UnsafeMutablePointer<UInt32>, position: UnsafeMutablePointer<GLMapPoint>) {
        variant.pointee = pins[index].imageID
        position.pointee = pins[index].position
    }

    func append(_ pin: Pin) {
        lock.lock()
        pins.append(pin)
        lock.unlock()
    }

    func remove(_ pin: Pin) {
        lock.lock()
        if let i = pins.firstIndex(where: { $0 == pin }) {
            pins.remove(at: i)
        }
        lock.unlock()
    }

    func findPin(point: CGPoint, mapView: GLMapView) -> Pin? {
        lock.lock()
        defer { lock.unlock() }
        let rect = CGRect(x: -20, y: -20, width: 40, height: 40).offsetBy(dx: point.x, dy: point.y)
        return pins.first { rect.contains(mapView.makeDisplayPoint(from: $0.position)) }
    }
}

class ImageGroupDemo: DemoMapViewController {
    private var pinGroup: PinGroup?
    private var imageGroup: GLMapImageGroup?
    private var pinCount: UInt32 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 37.3257, lon: -122.0353)
        map.mapZoomLevel = 14

        showAlert(message: "Long tap to add pin, tap pin to remove it")

        map.longPressGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let pt = gesture.location(in: map)
            addPin(at: map.makeMapPoint(fromDisplay: pt))
        }

        map.tapGestureBlock = { [weak self] gesture in
            guard let self, let pinGroup else { return }
            let pt = gesture.location(in: map)
            if let pin = pinGroup.findPin(point: pt, mapView: map) {
                removePin(pin)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let imageGroup {
            map.remove(imageGroup)
        }
    }

    private func addPin(at position: GLMapPoint) {
        if pinGroup == nil {
            pinGroup = PinGroup()
        }
        if imageGroup == nil {
            let group = GLMapImageGroup(callback: pinGroup!, andDrawOrder: 3)
            map.add(group)
            imageGroup = group
        }
        let pin = Pin(position: position, imageID: pinCount % 3)
        pinCount += 1
        pinGroup?.append(pin)
        imageGroup?.setNeedsUpdate(false)
    }

    private func removePin(_ pin: Pin) {
        pinGroup?.remove(pin)
        imageGroup?.setNeedsUpdate(false)
        if pinGroup?.pins.isEmpty == true, let imageGroup {
            map.remove(imageGroup)
            self.imageGroup = nil
            pinGroup = nil
        }
    }
}
