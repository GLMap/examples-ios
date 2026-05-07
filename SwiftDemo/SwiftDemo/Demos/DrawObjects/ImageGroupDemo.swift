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

    func startUpdate() {
        lock.lock()
    }

    func endUpdate() {
        lock.unlock()
    }

    func getVariantsCount() -> UInt32 {
        UInt32(variants.count)
    }

    func getVariant(_ index: UInt32, offset: UnsafeMutablePointer<CGPoint>) -> UIImage {
        let img = variants[Int(index)]
        offset.pointee = CGPoint(x: img.size.width / 2, y: 0)
        return img
    }

    func getImagesCount() -> UInt32 {
        UInt32(pins.count)
    }

    func getImageInfo(_ index: UInt32, variant: UnsafeMutablePointer<UInt32>, position: UnsafeMutablePointer<GLMapPoint>) {
        variant.pointee = pins[Int(index)].imageID
        position.pointee = pins[Int(index)].position
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

    /// Pre-populated POIs around Paris
    private let initialPins: [(lat: Double, lon: Double)] = [
        (48.8584, 2.2945), // Eiffel Tower
        (48.8606, 2.3376), // Louvre
        (48.8530, 2.3499), // Notre-Dame
        (48.8867, 2.3431), // Sacré-Cœur
        (48.8738, 2.2950), // Arc de Triomphe
        (48.8462, 2.3464), // Panthéon
        (48.8600, 2.3266), // Musée d'Orsay
        (48.8619, 2.2870), // Trocadéro
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        GLMapManager.shared.tileDownloadingAllowed = true
        map.mapGeoCenter = GLMapGeoPoint(lat: 48.8566, lon: 2.3522)
        map.mapZoomLevel = 13

        title = "Long press to add, tap to remove"

        pinGroup = PinGroup()
        let group = GLMapImageGroup(callback: pinGroup!, andDrawOrder: 3)
        map.add(group)
        imageGroup = group

        // Pre-populate pins
        for poi in initialPins {
            let pin = Pin(position: GLMapPoint(lat: poi.lat, lon: poi.lon), imageID: pinCount % 3)
            pinCount += 1
            pinGroup?.append(pin)
        }
        imageGroup?.setNeedsUpdate(false)

        map.longPressGestureBlock = { [weak self] gesture in
            guard let self, gesture.state == .began else { return }
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
        let pin = Pin(position: position, imageID: pinCount % 3)
        pinCount += 1
        pinGroup?.append(pin)
        imageGroup?.setNeedsUpdate(false)
    }

    private func removePin(_ pin: Pin) {
        pinGroup?.remove(pin)
        imageGroup?.setNeedsUpdate(false)
    }
}
