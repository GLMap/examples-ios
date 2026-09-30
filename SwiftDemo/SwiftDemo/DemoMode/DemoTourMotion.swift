import Foundation

/// Shared deterministic clock for the simulated walker, camera and native track
/// progress. It is an accelerated route preview, never a device GPS location.
enum DemoTourMotion {
    static let duration = 26.0
    static let searchStart = 4.0
    static let pinsStart = 5.1
    static let selectionStart = 8.0
    static let overviewStart = 10.7
    static let routeStart = 11.0
    static let revealStart = 12.0
    static let revealEnd = 13.4
    static let followStart = 14.2
    static let walkStart = 15.5
    static let arrival = 21.3
    static let returnStart = 21.7
    static let followEnd = 23.0
    static let outroStart = 23.1
    static let outroEnd = 24.3

    static func ease(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }

    static func walkFraction(at time: Double) -> Double {
        ease((time - walkStart) / (arrival - walkStart))
    }

    static func followWeight(at time: Double) -> Double {
        ease((time - followStart) / (walkStart - followStart))
            * (1 - ease((time - returnStart) / (followEnd - returnStart)))
    }

    static func outroOpacity(at time: Double) -> Double {
        1 - ease((time - outroStart) / (outroEnd - outroStart))
    }

    /// Convert travelled distance to the fractional vertex index used by GLMapTrack.
    /// Distances are cumulative, nondecreasing, and start at zero. Repeated vertices
    /// are allowed. Clamp the endpoints so the marker and progress finish together.
    static func pointIndex(at fraction: Double, distances: [Double]) -> Double {
        guard distances.count >= 2, let total = distances.last, total > 0 else { return 0 }
        if fraction <= 0 {
            return 0
        }
        if fraction >= 1 {
            return Double(distances.count - 1)
        }
        let target = fraction * total
        var lower = 1
        var upper = distances.count - 1
        while lower < upper {
            let middle = (lower + upper) / 2
            if distances[middle] < target {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        let length = distances[lower] - distances[lower - 1]
        let part = length > 0 ? (target - distances[lower - 1]) / length : 0
        return Double(lower - 1) + part
    }

    /// Shortest signed angular difference: never rotate 358° across north.
    static func angleDelta(from start: Double, to end: Double) -> Double {
        let delta = (end - start).truncatingRemainder(dividingBy: 360)
        return delta > 180 ? delta - 360 : delta < -180 ? delta + 360 : delta
    }

    static func mixAngle(from start: Double, to end: Double, fraction: Double) -> Double {
        start + angleDelta(from: start, to: end) * fraction
    }
}
