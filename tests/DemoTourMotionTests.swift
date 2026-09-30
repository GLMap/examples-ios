import Foundation

/// No SDK or API key is needed for these deterministic motion checks:
/// swiftc SwiftDemo/SwiftDemo/DemoMode/DemoTourMotion.swift tests/DemoTourMotionTests.swift -o /tmp/demo-motion-tests
@main
struct DemoTourMotionTests {
    static func main() {
        typealias M = DemoTourMotion
        precondition(M.duration == 26)
        precondition(M.walkFraction(at: M.walkStart) == 0)
        precondition(M.walkFraction(at: M.arrival) == 1)
        precondition(M.walkFraction(at: M.duration - 0.001) == 1)
        precondition(M.walkFraction(at: 0) == 0, "the next loop resets progress")
        precondition(M.followWeight(at: M.followStart) == 0)
        precondition(abs(M.followWeight(at: M.walkStart) - 1) < 1e-10)
        precondition(M.followWeight(at: M.arrival) == 1)
        precondition(M.followWeight(at: M.followEnd) == 0)
        precondition(M.outroOpacity(at: M.arrival) == 1, "show the full grey route before fading")
        precondition(M.outroOpacity(at: M.outroEnd) == 0)

        var previous = 0.0
        for frame in 0 ..< 3120 { // Two loops at 60 fps: no backward progress within a loop.
            let time = Double(frame % 1560) / 60
            if frame % 1560 == 0 {
                previous = 0
            }
            let progress = M.walkFraction(at: time)
            precondition(progress >= previous && (0 ... 1).contains(progress))
            precondition((0 ... 1).contains(M.followWeight(at: time)))
            precondition((0 ... 1).contains(M.outroOpacity(at: time)))
            previous = progress
        }
        precondition(M.angleDelta(from: 359, to: 1) == 2)
        precondition(M.angleDelta(from: 1, to: 359) == -2)
        precondition(M.mixAngle(from: -179, to: 179, fraction: 0.5) == -180)
        // Distance, not vertex count, determines the walker's fractional track index.
        precondition(M.pointIndex(at: 0.5, distances: [0, 10, 100]) == 1 + 40.0 / 90)
        precondition(M.pointIndex(at: -1, distances: [0, 10, 100]) == 0)
        precondition(M.pointIndex(at: 2, distances: [0, 10, 100]) == 2)
        precondition(M.pointIndex(at: 0.5, distances: []) == 0)
        precondition(M.pointIndex(at: 0.5, distances: [0]) == 0)
        precondition(M.pointIndex(at: 0.5, distances: [0, 0]) == 0)
        precondition(M.pointIndex(at: 0.5, distances: [0, 0, 10, 10, 20, 20]) == 2)
        precondition(M.pointIndex(at: 1, distances: [0, 0, 10, 10, 20, 20]) == 5)
        let distances = [0.0, 0, 2, 9, 9, 50, 100, 100]
        var previousIndex = 0.0
        for frame in 0 ... 1560 {
            let index = M.pointIndex(at: M.walkFraction(at: Double(frame) / 60), distances: distances)
            precondition(index.isFinite && index >= previousIndex && index <= Double(distances.count - 1))
            let segment = min(distances.count - 2, Int(index))
            let travelled = distances[segment] + (distances[segment + 1] - distances[segment]) * (index - Double(segment))
            precondition(abs(travelled - M.walkFraction(at: Double(frame) / 60) * 100) < 1e-9)
            previousIndex = index
        }
        print("DemoTourMotion: timeline, distance-based track progress, repeated vertices and heading checks passed")
    }
}
