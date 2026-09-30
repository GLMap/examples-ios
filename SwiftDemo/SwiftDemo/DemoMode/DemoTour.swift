import GLMap
import GLMapSwift
import GLRoute
import GLSearch
import UIKit

/// An automatic map → search → walking-route tour using real service results.
/// One timeline drives the native drawables, track progress and camera.
final class DemoTour: NSObject {
    private typealias Motion = DemoTourMotion
    private let map: GLMapView
    private let host: UIView
    private let overlay = DemoTourOverlay()
    private let onFailure: (String) -> Void
    private let start = GLMapGeoPoint(lat: 40.63318, lon: 14.60257)
    private let atrani = GLMapGeoPoint(lat: 40.63602, lon: 14.60980)
    private var pins: [GLMapImage] = []
    private var startDot: GLMapImage?
    private var finishRing: GLMapImage?
    private var userDot: GLMapImage?
    private var userArrow: GLMapImage?
    private var routeTrack: GLMapTrack?
    private var routeCasing: GLMapTrack?
    private var shape: [GLMapPoint] = []
    private var shapeDistances: [Double] = []
    private var followHeadings: [Double] = []
    private var routeMidpoint = GLMapGeoPoint(lat: 40.635, lon: 14.606)
    private var searchID: Int64 = 0
    private var routeID: Int64 = 0
    private var generation = 0
    private var active = false
    private var displayLink: CADisplayLink?
    private var epoch = 0.0
    private var pausedAt: Double?

    init(map: GLMapView, host: UIView, onFailure: @escaping (String) -> Void) {
        self.map = map
        self.host = host
        self.onFailure = onFailure
        super.init()
    }

    func startTour() {
        guard !active else { return }
        active = true
        generation += 1
        map.drawHillshades = true
        map.drawElevationLines = true
        map.altitudeScale = 1
        map.mapOrigin = CGPoint(x: 0.5, y: 0.5)
        setCamera(opening)
        overlay.frame = host.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.insertSubview(overlay, at: 0)
        preparePlaces()
    }

    func stop() {
        active = false
        generation += 1
        displayLink?.invalidate()
        displayLink = nil
        pausedAt = nil
        if searchID != 0 {
            GLSearchRequest.cancel(searchID); searchID = 0
        }
        if routeID != 0 {
            GLRouteRequest.cancel(routeID); routeID = 0
        }
        if let routeTrack {
            map.remove(routeTrack)
        }
        if let routeCasing {
            map.remove(routeCasing)
        }
        routeTrack = nil
        routeCasing = nil
        for image in pins + [startDot, finishRing, userDot, userArrow].compactMap({ $0 }) {
            map.remove(image)
        }
        pins.removeAll()
        startDot = nil
        finishRing = nil
        userDot = nil
        userArrow = nil
        shape.removeAll()
        shapeDistances.removeAll()
        followHeadings.removeAll()
        overlay.removeFromSuperview()
        map.cancelMapAnimations()
    }

    func pause() {
        guard displayLink != nil, pausedAt == nil else { return }
        pausedAt = CACurrentMediaTime()
        displayLink?.isPaused = true
    }

    func resume() {
        guard let pausedAt else { return }
        epoch += CACurrentMediaTime() - pausedAt
        self.pausedAt = nil
        displayLink?.isPaused = false
    }

    // MARK: - Search and routing

    private func preparePlaces() {
        let token = generation
        let request = GLSearchRequest(type: .search, text: "", center: atrani,
                                      limit: 60, locales: ["en", "native"], categories: ["restaurant"])
        searchID = request.startOnline { [weak self] results, error in
            guard let self, active, token == generation else { return }
            searchID = 0
            if let error {
                fail("Search failed: \(error.localizedDescription)"); return
            }
            guard let results else { fail("No restaurants found nearby."); return }
            let center = GLMapPoint(geoPoint: atrani)
            let candidates = results.array().filter {
                self.distance($0.point, center) < 1500 && !self.name(of: $0).isEmpty
            }.sorted { self.distance($0.point, center) < self.distance($1.point, center) }
            guard let selected = candidates.first else { fail("No restaurants found near Atrani."); return }
            var places = [selected]
            // A few separated results keep the overview readable; one is enough to run the tour.
            for object in candidates where places.count < 5 {
                if places.allSatisfy({ self.distance($0.point, object.point) > 75 }) {
                    places.append(object)
                }
            }
            prepareRoute(to: selected, places: places, token: token)
        }
    }

    private func prepareRoute(to selected: GLMapVectorObject, places: [GLMapVectorObject], token: Int) {
        let request = GLRouteRequest()
        request.setPedestrianWithOptions(.default)
        request.add(GLRoutePoint(pt: start, heading: .nan, type: .break))
        request.add(GLRoutePoint(pt: GLMapGeoPoint(point: selected.point), heading: .nan, type: .break))
        routeID = request.startOnline { [weak self] result, error in
            guard let self, active, token == generation else { return }
            routeID = 0
            if let error {
                fail("Routing failed: \(error.localizedDescription)"); return
            }
            guard let result,
                  let data = result.trackData(with: GLMapColor(red: 74, green: 82, blue: 239, alpha: 255)),
                  let casing = result.trackData(with: .white)
            else { fail("No walking route is available."); return }
            shape.removeAll()
            result.enumPoints(from: 0) { point, _ in self.shape.append(point) }
            guard shape.count >= 2 else { fail("The route has no walking geometry."); return }
            shapeDistances = [0]
            for index in 1 ..< shape.count {
                shapeDistances.append(shapeDistances[index - 1] + distance(shape[index - 1], shape[index]))
            }
            guard let length = shapeDistances.last, length.isFinite, length > 0,
                  result.length.isFinite, result.duration.isFinite
            else {
                fail("The route has invalid distance or duration.")
                return
            }
            prepareFollowHeadings()
            routeMidpoint = GLMapGeoPoint(point: result.bbox.center)
            routeCasing = makeTrack(data: casing, width: 10, order: 5)
            routeTrack = makeTrack(data: data, width: 6, order: 6)
            makeMarkers(places: places)
            let distanceText = result.length >= 1000 ? String(format: "%.1f km", result.length / 1000) : "\(Int((result.length / 10).rounded()) * 10) m"
            overlay.showPlace(name: name(of: selected), summary: "\(Int(ceil(result.duration / 60))) min  ·  \(distanceText)")
            epoch = CACurrentMediaTime()
            let link = CADisplayLink(target: self, selector: #selector(tick))
            displayLink = link
            link.add(to: .main, forMode: .common)
            if UIApplication.shared.applicationState != .active {
                pause()
            }
        }
    }

    private func fail(_ message: String) {
        overlay.showError(message)
        onFailure(message)
    }

    // MARK: - Native map objects

    private func makeTrack(data: GLMapTrackData, width: Int, order: Int32) -> GLMapTrack {
        let track = GLMapTrack(drawOrder: order)
        track.progressColor = GLMapColor(red: 0, green: 0, blue: 0, alpha: 0)
        track.progressIndex = 0
        track.progressEndIndex = 0
        track.hidden = true
        track.drawOnTopOfText = order == 6
        track.setData(data, style: GLMapVectorStyle.createStyle("{width:\(width)pt;}")!)
        map.add(track)
        return track
    }

    private func makeImage(_ image: UIImage, at point: GLMapPoint, order: Int32, offset: CGPoint? = nil) -> GLMapImage {
        let drawable = GLMapImage(drawOrder: order)
        drawable.setImage(image)
        drawable.position = point
        drawable.offset = offset ?? CGPoint(x: image.size.width / 2, y: image.size.height / 2)
        // Screen-facing artwork anchored to the terrain, not to an elevation-zero UIKit projection.
        drawable.drawTarget = .unbound
        drawable.hidden = true
        map.add(drawable)
        return drawable
    }

    private func makeMarkers(places: [GLMapVectorObject]) {
        let artwork = DemoTourArtwork.pin()
        pins = places.enumerated().map { index, place in
            makeImage(artwork, at: place.point, order: index == 0 ? 21 : 20, offset: CGPoint(x: 24, y: 3))
        }
        startDot = makeImage(DemoTourArtwork.startDot(), at: shape[0], order: 22)
        // The routed endpoint may be snapped to a nearby path rather than the POI centroid.
        finishRing = makeImage(DemoTourArtwork.finishRing(), at: shape[shape.count - 1], order: 23)
        userDot = makeImage(DemoTourArtwork.userDot(), at: shape[0], order: 100)
        userArrow = makeImage(DemoTourArtwork.userArrow(), at: shape[0], order: 101)
        userArrow?.rotatesWithMap = true
    }

    private func setOpacity(_ opacity: Double, on image: GLMapImage?) {
        let alpha = UInt8((min(1, max(0, opacity)) * 255).rounded())
        image?.hidden = alpha == 0
        // Mid-grey leaves RGB unchanged with GLMapImage's overlay tint blending.
        // Alpha zero disables tint, so explicitly hide at the fade endpoint.
        image?.tint = GLMapColor(red: 128, green: 128, blue: 128, alpha: alpha)
    }

    @objc private func tick(_ link: CADisplayLink) {
        guard active, shape.count >= 2 else { return }
        let time = max(0, link.timestamp - epoch).truncatingRemainder(dividingBy: Motion.duration)
        let walked = Motion.walkFraction(at: time)
        let current = position(along: walked)
        let outro = Motion.outroOpacity(at: time)
        // GLMap's origin is measured from the bottom; show more of the path ahead.
        map.mapOrigin = CGPoint(x: 0.5, y: 0.5 - 0.15 * Motion.followWeight(at: time))
        setCamera(camera(at: time))
        overlay.update(at: time)

        let selected = Motion.ease((time - Motion.selectionStart) / 0.4)
        for (index, pin) in pins.enumerated() {
            let appear = Motion.ease((time - Motion.pinsStart - Double(index) * 0.16) / 0.35)
            let others = index == 0 ? 1 : (1 - selected * 0.65) * (1 - Motion.ease((time - Motion.routeStart) / 0.6))
            setOpacity(appear * others * outro, on: pin)
            pin.scale = 0.65 + 0.17 * appear + (index == 0 ? 0.16 * selected : 0)
        }
        setOpacity(Motion.ease((time - Motion.routeStart) / 0.4) * (1 - Motion.ease((time - Motion.followStart) / 0.4)), on: startDot)
        let markerOpacity = Motion.ease((time - Motion.followStart) / 0.4) * outro
        userDot?.position = current.point
        userArrow?.position = current.point
        setOpacity(markerOpacity, on: userDot)
        setOpacity(markerOpacity * (1 - Motion.ease((time - Motion.arrival) / 0.3)), on: userArrow)
        userArrow?.angle = -Float(bearing(along: walked, radius: 0.02))

        let pulseStart = time < Motion.arrival ? Motion.revealEnd : Motion.arrival
        let pulse = min(1, max(0, (time - pulseStart) / 0.8))
        finishRing?.scale = 0.7 + pulse * 1.3
        setOpacity(time >= pulseStart && time < pulseStart + 0.8 ? 1 - pulse : 0, on: finishRing)

        // Reveal the route, then color its traversed prefix using the very same
        // fractional vertex index as the walker. There is no duplicate grey polyline.
        let revealing = time < Motion.revealEnd
        let reveal = Motion.ease((time - Motion.revealStart) / (Motion.revealEnd - Motion.revealStart))
        let endIndex = revealing ? position(along: reveal).index : Double.infinity
        let opacity = UInt8((255 * outro).rounded())
        routeTrack?.hidden = time < Motion.revealStart || time >= Motion.outroEnd
        routeTrack?.progressColor = revealing ? GLMapColor(red: 0, green: 0, blue: 0, alpha: 0) : GLMapColor(red: 132, green: 141, blue: 155, alpha: opacity)
        routeTrack?.progressIndex = revealing ? 0 : current.index
        routeTrack?.progressEndIndex = endIndex
        routeCasing?.hidden = time < Motion.revealStart || time >= Motion.outroEnd
        routeCasing?.progressColor = GLMapColor(red: 255, green: 255, blue: 255, alpha: time >= Motion.outroStart ? opacity : 0)
        routeCasing?.progressIndex = time >= Motion.outroStart ? current.index : 0
        routeCasing?.progressEndIndex = endIndex
    }

    // MARK: - Camera and route geometry

    private struct Camera {
        var lat: Double
        var lon: Double
        var zoom: Double
        var pitch: Double
        var angle: Double
    }

    private var opening: Camera {
        Camera(lat: 40.6368, lon: 14.6055, zoom: 15.1, pitch: 42, angle: -18)
    }

    private var searchCamera: Camera {
        Camera(lat: 40.6356, lon: 14.6062, zoom: 15.8, pitch: 8, angle: 0)
    }

    private var overview: Camera {
        Camera(lat: routeMidpoint.lat + 0.0003, lon: routeMidpoint.lon, zoom: 15.95, pitch: 20, angle: -4)
    }

    private func camera(at time: Double) -> Camera {
        if time < Motion.searchStart {
            return mix(opening, searchCamera, Motion.ease(time / Motion.searchStart))
        }
        if time < Motion.overviewStart {
            return searchCamera
        }
        if time < Motion.revealStart {
            return mix(searchCamera, overview, Motion.ease((time - Motion.overviewStart) / (Motion.revealStart - Motion.overviewStart)))
        }
        if time < Motion.followStart {
            return overview
        }
        if time < Motion.walkStart {
            return mix(overview, flightCamera(0), Motion.followWeight(at: time))
        }
        if time < Motion.returnStart {
            return flightCamera(Motion.walkFraction(at: time))
        }
        if time < Motion.followEnd {
            return mix(overview, flightCamera(1), Motion.followWeight(at: time))
        }
        return mix(overview, opening, Motion.ease((time - Motion.followEnd) / (Motion.duration - Motion.followEnd)))
    }

    private func flightCamera(_ fraction: Double) -> Camera {
        // Only the camera is spatially smoothed. Marker and progress stay on the exact route.
        let positions = [-0.025, 0, 0, 0.025].map { GLMapGeoPoint(point: position(along: fraction + $0).point) }
        let lat = positions.reduce(0) { $0 + $1.lat } / 4
        let lon = positions.reduce(0) { $0 + $1.lon } / 4
        let sample = min(100, max(0, fraction * 100))
        let index = min(99, Int(sample))
        let angle = Motion.mixAngle(from: followHeadings[index], to: followHeadings[index + 1], fraction: sample - Double(index))
        return Camera(lat: lat, lon: lon, zoom: 16.85, pitch: 43, angle: angle)
    }

    private func prepareFollowHeadings() {
        followHeadings = []
        for sample in 0 ... 100 {
            let angle = bearing(along: Double(sample) / 100, radius: 0.12)
            followHeadings.append(Motion.mixAngle(from: followHeadings.last ?? angle, to: angle, fraction: 0.25))
        }
    }

    private func bearing(along fraction: Double, radius: Double) -> Double {
        let a = GLMapGeoPoint(point: position(along: fraction - radius).point)
        let b = GLMapGeoPoint(point: position(along: fraction + radius).point)
        return a.bearingTo(b)
    }

    private func position(along fraction: Double) -> (point: GLMapPoint, index: Double) {
        let index = Motion.pointIndex(at: fraction, distances: shapeDistances)
        let segment = min(shape.count - 2, Int(index))
        let part = index - Double(segment)
        let a = shape[segment], b = shape[segment + 1]
        return (GLMapPoint(x: a.x + (b.x - a.x) * part, y: a.y + (b.y - a.y) * part), index)
    }

    private func setCamera(_ camera: Camera) {
        map.mapGeoCenter = GLMapGeoPoint(lat: camera.lat, lon: camera.lon)
        map.mapZoomLevel = camera.zoom
        map.mapPitch = Float(camera.pitch)
        map.mapAngle = Float(camera.angle)
    }

    private func mix(_ a: Camera, _ b: Camera, _ t: Double) -> Camera {
        Camera(lat: a.lat + (b.lat - a.lat) * t, lon: a.lon + (b.lon - a.lon) * t,
               zoom: a.zoom + (b.zoom - a.zoom) * t, pitch: a.pitch + (b.pitch - a.pitch) * t,
               angle: Motion.mixAngle(from: a.angle, to: b.angle, fraction: t))
    }

    private func name(of object: GLMapVectorObject) -> String {
        object.localizedName(map.localeSettings)?.asString() ?? ""
    }

    private func distance(_ a: GLMapPoint, _ b: GLMapPoint) -> Double {
        GLMapGeoPoint(point: a).distanceTo(GLMapGeoPoint(point: b))
    }
}
