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
        case offlineMap
        case darkTheme
        case embeddMap
        case onlineMap
        case routing
        case routeTracker
        case rasterOnlineMap
        case zoomToBBox
        case offlineSearch
        case notifications
        case singleImage
        case multiImage
        case markerLayer
        case markerLayerWithClustering
        case markerLayerWithMapCSSClustering
        case track
        case multiLine
        case polygon
        case geoJSON
        case screenshot
        case fonts
        case flyTo
        case downloadInBBox
        case styleReload
        case downloadMap
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
        TableRow(.offlineMap, name: "Open offline map"),
        TableRow(.darkTheme, name: "Dark theme"),
        TableRow(.embeddMap, name: "Open embedd map"),
        TableRow(.onlineMap, name: "Open online map", description: "Downloads tiles one by one"),
        TableRow(.routing, name: "Routing", description: "Offline routing requires downloaded navigation data"),
        TableRow(.routeTracker, name: "Route Tracker", description: "Tracking user while it moves along the route"),
        TableRow(.rasterOnlineMap, name: "Raster online map", description: "Downloads raster tiles one by one from custom tile source"),

        TableRow(.zoomToBBox, name: "Zoom to bbox"),
        TableRow(.offlineSearch, name: "Offline search"),
        TableRow(.notifications, name: "Notification test"),
        TableRow(.singleImage, name: "GLMapImage demo", description: "For one pin or any other image"),
        TableRow(.multiImage, name: "GLMapImageGroup demo", description: "For large set of pins with smaller set of images"),

        TableRow(.markerLayer, name: "GLMapMarkerLayer demo"),
        TableRow(.markerLayerWithClustering, name: "GLMapMarkerLayer with clustering"),
        TableRow(.markerLayerWithMapCSSClustering, name: "GLMapMarkerLayer with MapCSS clustering"),

        TableRow(.track, name: "GPS track recording"),
        TableRow(.multiLine, name: "Add multiline"),

        TableRow(.polygon, name: "Add polygon"),
        TableRow(.geoJSON, name: "Load GeoJSON"),
        TableRow(.screenshot, name: "Take screenshot"),
        TableRow(.fonts, name: "Fonts"),
        TableRow(.flyTo, name: "Fly to"),

        TableRow(.downloadInBBox, name: "Download data in bounding box"),
        TableRow(.styleReload, name: "Style live reload"),

        TableRow(.downloadMap, name: "Download offline map"),
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

        if row.id == Demo.downloadMap {
            performSegue(withIdentifier: "DownloadMaps", sender: nil)
        } else if row.id == Demo.routeTracker {
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
