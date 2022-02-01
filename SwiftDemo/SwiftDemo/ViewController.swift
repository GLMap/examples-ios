//
//  ViewController.swift
//  SwiftDemo
//
//  Created by Evgen Bodunov on 11/14/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import GLMapSwift
import GLRoute
import UIKit

class ViewController: UITableViewController {
    public enum Demo {
        case OfflineMap
        case DarkTheme
        case EmbeddMap
        case OnlineMap
        case Routing
        case RouteTracker
        case RasterOnlineMap
        case ZoomToBBox
        case OfflineSearch
        case Notifications
        case SingleImage
        case MultiImage
        case MarkerLayer
        case MarkerLayerWithClustering
        case MarkerLayerWithMapCSSClustering
        case Track
        case MultiLine
        case Polygon
        case GeoJSON
        case Screenshot
        case Fonts
        case FlyTo
        case DownloadInBBox
        case StyleReload

        case DownloadMap
    }

    struct TableRow {
        let id: Demo
        let name: String
        let description: String?

        init(_ id: Demo, name: String) {
            self.id = id
            self.name = name
            description = nil
        }

        init(_ id: Demo, name: String, description: String) {
            self.id = id
            self.name = name
            self.description = description
        }
    }

    let tableRows = [
        TableRow(.OfflineMap, name: "Open offline map"),
        TableRow(.DarkTheme, name: "Dark theme"),
        TableRow(.EmbeddMap, name: "Open embedd map"),
        TableRow(.OnlineMap, name: "Open online map", description: "Downloads tiles one by one"),
        TableRow(.Routing, name: "Routing", description: "Offline routing requires downloaded navigation data"),
        TableRow(.RouteTracker, name: "Route Tracker", description: "Tracking user while it moves along the route"),
        TableRow(.RasterOnlineMap, name: "Raster online map", description: "Downloads raster tiles one by one from custom tile source"),

        TableRow(.ZoomToBBox, name: "Zoom to bbox"),
        TableRow(.OfflineSearch, name: "Offline search"),
        TableRow(.Notifications, name: "Notification test"),
        TableRow(.SingleImage, name: "GLMapDrawable demo", description: "For one pin or any other image"),
        TableRow(.MultiImage, name: "GLMapImageGroup demo", description: "For large set of pins with smaller set of images"),

        TableRow(.MarkerLayer, name: "GLMapMarkerLayer demo"),
        TableRow(.MarkerLayerWithClustering, name: "GLMapMarkerLayer with clustering"),
        TableRow(.MarkerLayerWithMapCSSClustering, name: "GLMapMarkerLayer with MapCSS clustering"),

        TableRow(.Track, name: "GPS track recording"),
        TableRow(.MultiLine, name: "Add multiline"),

        TableRow(.Polygon, name: "Add polygon"),
        TableRow(.GeoJSON, name: "Load GeoJSON"),
        TableRow(.Screenshot, name: "Take screenshot"),
        TableRow(.Fonts, name: "Fonts"),
        TableRow(.FlyTo, name: "Fly to"),

        TableRow(.DownloadInBBox, name: "Download data in bounding box"),
        TableRow(.StyleReload, name: "Style live reload"),

        TableRow(.DownloadMap, name: "Download offline map"),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        title = "GLMap examples"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return tableRows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        let row = tableRows[indexPath.row]

        cell.textLabel?.text = row.name
        cell.detailTextLabel?.text = row.description

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = tableRows[indexPath.row]

        if row.id == Demo.DownloadMap {
            performSegue(withIdentifier: "DownloadMaps", sender: nil)
        } else if row.id == Demo.RouteTracker {
            let start = RoutePoint(pt: GLMapGeoPoint(lat: +37.405054, lon: -122.156626),
                                   index: 0,
                                   isCurrentLocation: true)
            let finish = RoutePoint(pt: GLMapGeoPoint(lat: +37.335055, lon: -122.026958),
                                    index: 1,
                                    isCurrentLocation: false)

            let params = RouteParams(points: [start, finish], mode: .drive)
            let task = BuildRouteTask(params: params)
            task.start { [weak task] in
                switch task?.result {
                case let .success(result):
                    let vc = RouteTrackerViewController(result)
                    self.navigationController?.pushViewController(vc, animated: true)
                case let .error(error):
                    NSLog("Error building route: \(error.localizedDescription)")
                default:
                    NSLog("Unexpected result")
                }
            }
        } else {
            performSegue(withIdentifier: "Map", sender: row.id)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Map" {
            if let mapViewController = segue.destination as? MapViewController {
                if let demoCase = sender as? Demo {
                    mapViewController.currentDemo = demoCase
                }
            }
        }
    }
}
