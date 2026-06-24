import Foundation

enum DemoRegistry {
    static let demos: [DemoDescriptor] = [
        // MARK: - Map Display

        DemoDescriptor(
            title: "Online Map",
            subtitle: "Vector tiles, custom raster source, tap interaction",
            category: .mapDisplay,
            icon: "globe",
            makeViewController: { OnlineMapDemo() }
        ),
        DemoDescriptor(
            title: "Dark Theme",
            subtitle: "GLMapVectorCascadeStyle with theme options",
            category: .mapDisplay,
            icon: "moon.fill",
            makeViewController: { DarkThemeDemo() }
        ),
        DemoDescriptor(
            title: "3D Terrain",
            subtitle: "Altitude scale, pitch, hillshades, elevation lines",
            category: .mapDisplay,
            icon: "mountain.2.fill",
            isNew: true,
            makeViewController: { TerrainDemo() }
        ),

        // MARK: - Camera

        DemoDescriptor(
            title: "Fly To",
            subtitle: "GLMapAnimation.flyToPoint",
            category: .camera,
            icon: "airplane",
            makeViewController: { FlyToDemo() }
        ),
        DemoDescriptor(
            title: "Zoom to BBox",
            subtitle: "mapScaleForBBox, animate to fit",
            category: .camera,
            icon: "arrow.up.left.and.arrow.down.right",
            makeViewController: { ZoomToBBoxDemo() }
        ),

        // MARK: - Draw Objects

        DemoDescriptor(
            title: "Image",
            subtitle: "GLMapImage — pin on map, animated position",
            category: .drawObjects,
            icon: "mappin",
            makeViewController: { ImageDemo() }
        ),
        DemoDescriptor(
            title: "Image Group",
            subtitle: "GLMapImageGroup — many pins, shared images",
            category: .drawObjects,
            icon: "mappin.and.ellipse",
            makeViewController: { ImageGroupDemo() }
        ),
        DemoDescriptor(
            title: "Markers & Clustering",
            subtitle: "GLMapMarkerLayer with clustering",
            category: .drawObjects,
            icon: "circle.hexagongrid",
            makeViewController: { MarkerClusteringDemo() }
        ),
        DemoDescriptor(
            title: "Balloon",
            subtitle: "GLMapBalloon — text callout on tap",
            category: .drawObjects,
            icon: "text.bubble",
            makeViewController: { BalloonDemo() }
        ),
        DemoDescriptor(
            title: "Track Arrows",
            subtitle: "GLMapTrack with directional arrows",
            category: .drawObjects,
            icon: "arrow.right",
            isNew: true,
            makeViewController: { TrackArrowsDemo() }
        ),
        DemoDescriptor(
            title: "User Location",
            subtitle: "GLMapUserLocation helper",
            category: .drawObjects,
            icon: "location.fill",
            isNew: true,
            makeViewController: { UserLocationDemo() }
        ),

        // MARK: - Vector Data

        DemoDescriptor(
            title: "Lines & Polygons",
            subtitle: "GLMapVectorLayer with line and polygon",
            category: .vectorData,
            icon: "skew",
            makeViewController: { LinesPolygonsDemo() }
        ),
        DemoDescriptor(
            title: "GeoJSON",
            subtitle: "Load file, display, tap to identify",
            category: .vectorData,
            icon: "doc.text",
            makeViewController: { GeoJSONDemo() }
        ),
        DemoDescriptor(
            title: "GPS Track",
            subtitle: "GLMapTrack recording live GPS data",
            category: .vectorData,
            icon: "point.topleft.down.to.point.bottomright.curvepath.fill",
            makeViewController: { GPSTrackDemo() }
        ),

        // MARK: - Search

        DemoDescriptor(
            title: "Search",
            subtitle: "Online and Offline requests",
            category: .search,
            icon: "magnifyingglass",
            isNew: true,
            makeViewController: { SearchDemo() }
        ),
        DemoDescriptor(
            title: "POI Tap",
            subtitle: "Tap map labels to identify objects",
            category: .search,
            icon: "hand.tap",
            makeViewController: { POITapDemo() }
        ),

        // MARK: - Routing

        DemoDescriptor(
            title: "Route Building",
            subtitle: "GLRouteRequest online/offline",
            category: .routing,
            icon: "arrow.triangle.turn.up.right.diamond",
            makeViewController: { RouteBuildingDemo() }
        ),
        DemoDescriptor(
            title: "Turn-by-Turn Navigation",
            subtitle: "GLRouteTracker with maneuvers",
            category: .routing,
            icon: "location.north.line",
            makeViewController: { TurnByTurnDemo() }
        ),

        // MARK: - Offline Data

        DemoDescriptor(
            title: "Download Maps",
            subtitle: "GLMapManager.updateMapList, downloadDataSets",
            category: .offlineData,
            icon: "arrow.down.circle",
            makeViewController: { DownloadMapsDemo() }
        ),
        DemoDescriptor(
            title: "Download BBox",
            subtitle: "Download map + nav + elevation for area",
            category: .offlineData,
            icon: "square.dashed",
            makeViewController: { DownloadBBoxDemo() }
        ),
    ]

    static var groupedDemos: [(category: DemoCategory, demos: [DemoDescriptor])] {
        var groups: [(category: DemoCategory, demos: [DemoDescriptor])] = []
        for category in DemoCategory.allCases {
            let categoryDemos = demos.filter { $0.category == category }
            if !categoryDemos.isEmpty {
                groups.append((category: category, demos: categoryDemos))
            }
        }
        return groups
    }
}
