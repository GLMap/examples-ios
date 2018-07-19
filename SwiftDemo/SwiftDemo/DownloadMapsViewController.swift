//
//  DownloadMapsViewController.swift
//  GLMap
//
//  Created by Evgen Bodunov on 11/28/16.
//  Copyright © 2016 Evgen Bodunov. All rights reserved.
//

import GLMap
import GLMapSwift
import UIKit

class DownloadMapsViewController: UITableViewController {
    var mapsOnDevice: [GLMapInfo] = [], mapsOnServer: [GLMapInfo] = [], allMaps: [GLMapInfo] = []

    override func viewWillAppear(_: Bool) {
        if allMaps.count == 0 { // map data could be set during preparing for segue
            if let cachedMapList = GLMapManager.shared.cachedMapList() {
                setMaps(cachedMapList)
            }
            updateMaps()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(DownloadMapsViewController.mapUpdated), name: GLMapInfo.stateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadMapsViewController.progressUpdated), name: GLMapDownloadTask.downloadProgress, object: nil)
    }

    func updateMaps() {
        GLMapManager.shared.updateMapList { (fetchedMaps: [GLMapInfo]?, _, error: Error?) in
            if error != nil {
                NSLog("Map downloading error \(error!.localizedDescription)")
            } else {
                if let maps = fetchedMaps {
                    self.setMaps(maps)
                }
            }
        }
    }

    @objc func mapUpdated(notification _: Notification) {
        setMaps(allMaps)
    }

    @objc func progressUpdated(notification: Notification) {
        if let task = notification.object as? GLMapDownloadTask {
            updateCellForMap(task.map)
        }
    }

    func updateCellForMap(_ map: GLMapInfo) {
        if let index = mapsOnDevice.index(of: map) {
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        } else {
            setMaps(allMaps)
        }
    }

    func isOnDevice(_ map: GLMapInfo) -> Bool {
        return map.state(for: .map) != .notDownloaded || map.state(for: .navigation) != .notDownloaded
    }

    func setMaps(_ maps: [GLMapInfo]) {
        // Unroll map groups for Africa, Caribbean, and Oceania
        // maps = [self unrollMapArray:maps]

        // Detect and pass user location there. If there is no location detected yet, just don't sort an array by location. ;)
        // let userLocation = GLMapGeoPoint.init(lat: 40.7, lon: -73.9)
        // let sortedMaps = sort(maps: maps, byDistanceFrom: userLocation)

        let sortedMaps = sort(maps: maps, byNameIn: "en")

        allMaps = sortedMaps

        mapsOnDevice.removeAll()
        mapsOnServer.removeAll()

        for map in allMaps {
            let subMaps = map.subMaps

            if subMaps.count != 0 {
                var downloadedSubMaps = 0

                for subInfo in subMaps {
                    if isOnDevice(subInfo) {
                        downloadedSubMaps = downloadedSubMaps + 1
                    }
                }

                if downloadedSubMaps > 0 {
                    mapsOnDevice.append(map)
                }
                if downloadedSubMaps != subMaps.count {
                    mapsOnServer.append(map)
                }
            } else if isOnDevice(map) {
                mapsOnDevice.append(map)
            } else {
                mapsOnServer.append(map)
            }
        }

        tableView.reloadData()
    }

    func sort(maps: [GLMapInfo], byDistanceFrom location: GLMapGeoPoint) -> [GLMapInfo] {
        return maps.sorted(by: { (a: GLMapInfo, b: GLMapInfo) -> Bool in
            a.distance(from: location) < b.distance(from: location)
        })
    }

    func sort(maps: [GLMapInfo], byNameIn locale: String) -> [GLMapInfo] {
        return maps.sorted(by: { (a: GLMapInfo, b: GLMapInfo) -> Bool in
            var aName = a.name(inLanguage: locale)
            if aName == nil {
                aName = a.name()
            }

            var bName = b.name(inLanguage: locale)
            if bName == nil {
                bName = b.name()
            }

            if aName != nil && bName != nil {
                return aName! < bName!
            }

            return false
        })
    }

    // MARK: Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 2
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Maps on device"
        } else {
            return "Maps on server"
        }
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return mapsOnDevice.count
        } else {
            return mapsOnServer.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "MapCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        let map: GLMapInfo
        if indexPath.section == 0 {
            map = mapsOnDevice[indexPath.row]
            if map.subMaps.count > 0 {
                cell.accessoryType = .disclosureIndicator
                cell.detailTextLabel?.text = nil
            } else if let task = GLMapManager.shared.downloadTask(forMap: map) {
                let progress = Float(task.downloaded) * 100 / Float(task.total)
                cell.detailTextLabel?.text = String(format: "Downloading %.2f%%", progress)
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .none

                if map.haveState(.needResume, inDataSets: .all) {
                    cell.detailTextLabel?.text = "Resume"
                } else if map.haveState(.needUpdate, inDataSets: .all) {
                    cell.detailTextLabel?.text = "Update"
                } else {
                    let size = map.sizeOnDisk(forDataSets: .all)
                    if size != 0 {
                        cell.accessoryView = nil
                        cell.detailTextLabel?.text = String(format: "%.2f MB", Double(size) / 1_000_000)
                    } else {
                        cell.detailTextLabel?.text = nil
                    }
                }
            }
        } else {
            map = mapsOnServer[indexPath.row]

            if map.subMaps.count > 0 {
                cell.accessoryType = .disclosureIndicator
                cell.detailTextLabel?.text = nil
            } else {
                cell.accessoryType = .none
                cell.detailTextLabel?.text = String(format: "%.2f MB", Double(map.sizeOnServer(forDataSets: .all)) / 1_000_000)
            }
        }

        cell.textLabel?.text = map.name(inLanguage: "en")
        // cell.detailTextLabel?.text = row.description

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let map: GLMapInfo
        if indexPath.section == 0 {
            map = mapsOnDevice[indexPath.row]
        } else {
            map = mapsOnServer[indexPath.row]
        }

        if map.subMaps.count > 0 {
            performSegue(withIdentifier: "OpenSubmap", sender: map)
        } else {
            if let downloadTask = GLMapManager.shared.downloadTask(forMap: map) {
                downloadTask.cancel()
            } else {
                startDownloadingMap(map, retryCount: 3)
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func startDownloadingMap(_ map: GLMapInfo, retryCount: Int) {
        if retryCount > 0 {
            GLMapManager.shared.downloadDataSets(.all, forMap: map, withCompletionBlock: { (task: GLMapDownloadTask) in
                if let error = task.error as NSError? {
                    NSLog("Map downloading error: \(error)")
                    // CURLE_OPERATION_TIMEDOUT = 28 http://curl.haxx.se/libcurl/c/libcurl-errors.html
                    if error.domain == "CURL" && error.code == 28 {
                        self.startDownloadingMap(map, retryCount: 2)
                    }
                }
            })
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenSubmap" {
            if let mapViewController = segue.destination as? DownloadMapsViewController {
                if let map = sender as? GLMapInfo {
                    mapViewController.setMaps(map.subMaps)
                    mapViewController.title = map.name(inLanguage: "en")
                }
            }
        }
    }

    override func tableView(_: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 0 {
            let map = mapsOnDevice[indexPath.row]

            if map.subMaps.count == 0 {
                return .delete
            }
        }
        return .none
    }

    override func tableView(_: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let map = mapsOnDevice[indexPath.row]

            GLMapManager.shared.deleteDataSets(.all, forMap: map)
            setMaps(allMaps)
        }
    }
}
