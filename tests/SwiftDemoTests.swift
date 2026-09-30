import CoreLocation
import GLMap
import GLMapSwift
import GLSearch
@testable import SwiftDemo
import XCTest

@MainActor
final class SwiftDemoTests: XCTestCase {
    func testCancelledBackGestureKeepsImageTapHandlerAndTilePolicy() {
        let previous = GLMapManager.shared.tileDownloadingAllowed
        defer { GLMapManager.shared.tileDownloadingAllowed = previous }
        GLMapManager.shared.tileDownloadingAllowed = false
        let controller = ImageDemo()
        controller.loadViewIfNeeded()
        controller.viewWillAppear(false)
        XCTAssertTrue(GLMapManager.shared.tileDownloadingAllowed)
        XCTAssertNotNil(controller.map.tapGestureBlock)

        // UIKit calls willDisappear even if an interactive pop is later cancelled.
        controller.viewWillDisappear(true)
        controller.viewWillAppear(true)
        XCTAssertNotNil(controller.map.tapGestureBlock)
        XCTAssertTrue(GLMapManager.shared.tileDownloadingAllowed)
        controller.viewDidDisappear(false)
        XCTAssertFalse(GLMapManager.shared.tileDownloadingAllowed)

        controller.viewWillAppear(false)
        XCTAssertTrue(GLMapManager.shared.tileDownloadingAllowed)
        XCTAssertNotNil(controller.map.tapGestureBlock)
        controller.viewDidDisappear(false)
        XCTAssertFalse(GLMapManager.shared.tileDownloadingAllowed)
    }

    func testImageGroupGesturesSurviveCancelledBackGesture() {
        let controller = ImageGroupDemo()
        controller.loadViewIfNeeded()
        controller.viewWillAppear(false)
        defer { controller.viewDidDisappear(false) }
        controller.viewWillDisappear(true)
        controller.viewWillAppear(true)
        XCTAssertNotNil(controller.map.tapGestureBlock)
        XCTAssertNotNil(controller.map.longPressGestureBlock)
    }

    func testOfflineScreenRestoresPreviousTilePolicy() {
        final class OfflineController: DemoMapViewController {
            override var usesOnlineTiles: Bool {
                false
            }
        }
        let previous = GLMapManager.shared.tileDownloadingAllowed
        defer { GLMapManager.shared.tileDownloadingAllowed = previous }
        GLMapManager.shared.tileDownloadingAllowed = true
        let controller = OfflineController()
        controller.loadViewIfNeeded()
        controller.viewWillAppear(false)
        XCTAssertFalse(GLMapManager.shared.tileDownloadingAllowed)
        controller.viewDidDisappear(false)
        XCTAssertTrue(GLMapManager.shared.tileDownloadingAllowed)
    }

    func testMontenegroIsBundled() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "Montenegro", ofType: "vm"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testBundledMapSupportsOfflineRestaurantSearch() {
        // Opening the example repeatedly must not register the same dataset twice.
        for _ in 0 ..< 2 {
            let controller = SearchDemo()
            controller.loadViewIfNeeded()
            XCTAssertNil(controller.navigationItem.prompt)
        }
        let completed = expectation(description: "Offline search")
        let request = GLSearchRequest(type: .search, text: "", center: GLMapGeoPoint(lat: 42.4341, lon: 19.26),
                                      limit: 10, locales: ["en", "native"], categories: ["restaurant"])
        let task = request.startOffline { results, error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(results?.count ?? 0, 0)
            completed.fulfill()
        }
        defer {
            if task != 0 {
                GLSearchRequest.cancel(task)
            }
        }
        wait(for: [completed], timeout: 20)
    }

    func testGeoJSONLoadsOffMainThreadAndInstallsTapHandler() {
        let controller = GeoJSONDemo()
        controller.loadViewIfNeeded()
        XCTAssertNil(controller.map.tapGestureBlock, "Parsing must not finish synchronously in viewDidLoad")
        let ready = expectation(for: NSPredicate { _, _ in
            controller.map.tapGestureBlock != nil
        }, evaluatedWith: nil)
        wait(for: [ready], timeout: 20)
        XCTAssertNotEqual(controller.title, "GeoJSON failed")
    }

    func testTourOverlayAdaptsToPortraitAndLandscape() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let overlay = DemoTourOverlay()
        overlay.frame = host.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(overlay)
        overlay.showPlace(name: "Restaurant", summary: "12 min · 600 m")
        for size in [CGSize(width: 390, height: 844), CGSize(width: 844, height: 390)] {
            host.frame.size = size
            host.layoutIfNeeded()
            overlay.layoutIfNeeded()
            for time in [0.0, 6, 9, 13.8, 17, 22, 25] {
                overlay.update(at: time)
                for view in overlay.subviews where view.alpha > 0 {
                    XCTAssertGreaterThanOrEqual(view.frame.minX, 0)
                    XCTAssertLessThanOrEqual(view.frame.maxX, size.width)
                    XCTAssertGreaterThanOrEqual(view.frame.minY, 0)
                    XCTAssertLessThanOrEqual(view.frame.maxY, size.height)
                }
            }
        }
    }

    func testTrackProgressUsesDistanceAndHandlesRepeatedVertices() {
        let distances = [0.0, 0, 10, 100, 100]
        XCTAssertEqual(DemoTourMotion.pointIndex(at: 0, distances: distances), 0)
        XCTAssertEqual(DemoTourMotion.pointIndex(at: 0.5, distances: distances), 2 + 40.0 / 90, accuracy: 1e-12)
        XCTAssertEqual(DemoTourMotion.pointIndex(at: 1, distances: distances), 4)
        XCTAssertEqual(DemoTourMotion.angleDelta(from: 359, to: 1), 2)
    }
}
