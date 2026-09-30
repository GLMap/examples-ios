import GLMap
import GLMapSwift
import UIKit

class DownloadMapsDemo: UITableViewController, UISearchResultsUpdating {
    private let searchController = UISearchController(searchResultsController: nil)
    private var mapsOnDevice: [GLMapInfo] = []
    private var mapsOnServer: [GLMapInfo] = []
    private var allMaps: [GLMapInfo] = []
    private var mapGroup: GLMapInfo?
    private var observers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MapCell")
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search maps"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        if let mapGroup {
            setMaps(mapGroup.subMaps)
        } else {
            if let cached = GLMapManager.shared.cachedMapList() {
                setMaps(cached)
            }
            GLMapManager.shared.updateMapList { [weak self] maps, _, error in
                if let error {
                    self?.showError("Map list unavailable", message: error.localizedDescription)
                }
                if let maps {
                    self?.setMaps(maps)
                }
            }
        }

        observers = [
            NotificationCenter.default.addObserver(forName: GLMapInfo.stateChanged, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                setMaps(allMaps)
            },
            NotificationCenter.default.addObserver(forName: GLMapDownloadTask.downloadProgress, object: nil, queue: .main) { [weak self] notification in
                guard let self, let task = notification.object as? GLMapDownloadTask else { return }
                updateCell(for: task.map)
            },
        ]
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setMaps(_ maps: [GLMapInfo]) {
        allMaps = maps.sorted { ($0.name(inLanguage: "en") ?? $0.name()) < ($1.name(inLanguage: "en") ?? $1.name()) }
        updateVisibleMaps()
    }

    func updateSearchResults(for _: UISearchController) {
        updateVisibleMaps()
    }

    private func updateVisibleMaps() {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let visibleMaps = query.isEmpty ? allMaps : allMaps.filter { info in
            info.names.values.contains { $0.localizedStandardContains(query) }
                || info.isoCode?.localizedStandardContains(query) == true
        }
        mapsOnDevice = visibleMaps.filter { isOnDevice($0) || $0.subMaps.contains(where: { isOnDevice($0) }) }
        mapsOnServer = visibleMaps.filter { !isOnDevice($0) && !$0.subMaps.contains(where: { isOnDevice($0) }) }
        tableView.reloadData()
    }

    private func isOnDevice(_ info: GLMapInfo) -> Bool {
        info.state(for: .map) != .notDownloaded
            || info.state(for: .navigation) != .notDownloaded
            || info.state(for: .elevation) != .notDownloaded
    }

    private func showError(_ title: String, message: String) {
        navigationItem.prompt = message
        guard viewIfLoaded?.window != nil, presentedViewController == nil else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateCell(for mapInfo: GLMapInfo) {
        if let idx = mapsOnDevice.firstIndex(of: mapInfo) {
            tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
        } else {
            setMaps(allMaps)
        }
    }

    // MARK: - Table view

    override func numberOfSections(in _: UITableView) -> Int {
        2
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "On Device" : "Available"
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? mapsOnDevice.count : mapsOnServer.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath)
        let info = indexPath.section == 0 ? mapsOnDevice[indexPath.row] : mapsOnServer[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = info.name(inLanguage: "en") ?? info.name()

        if info.subMaps.count > 0 {
            cell.accessoryType = .disclosureIndicator
        } else if let tasks = GLMapManager.shared.downloadTasks(forMap: info, dataSets: .all), !tasks.isEmpty {
            let downloaded = tasks.reduce(0.0) { $0 + Double($1.downloaded) }
            let total = tasks.reduce(0.0) { $0 + Double($1.total) }
            if total > 0 {
                config.secondaryText = String(format: "Downloading %d data sets · %.1f%%", tasks.count, downloaded * 100 / total)
            } else {
                config.secondaryText = "Starting download..."
            }
            cell.accessoryType = .none
        } else if indexPath.section == 0 {
            let size = info.sizeOnDisk(forDataSets: .all)
            config.secondaryText = String(format: "%.2f MB", Double(size) / 1_000_000)
            cell.accessoryType = .none
        } else {
            config.secondaryText = String(format: "%.2f MB", Double(info.sizeOnServer(forDataSets: .all)) / 1_000_000)
            cell.accessoryType = .none
        }

        cell.contentConfiguration = config
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let info = indexPath.section == 0 ? mapsOnDevice[indexPath.row] : mapsOnServer[indexPath.row]

        if info.subMaps.count > 0 {
            let sub = DownloadMapsDemo(style: .grouped)
            sub.mapGroup = info
            sub.title = info.name(inLanguage: "en") ?? info.name()
            navigationController?.pushViewController(sub, animated: true)
        } else {
            if let tasks = GLMapManager.shared.downloadTasks(forMap: info, dataSets: .all), !tasks.isEmpty {
                // A map download consists of independent map, navigation and elevation tasks.
                for task in tasks {
                    task.cancel()
                }
            } else {
                GLMapManager.shared.downloadDataSets(.all, forMap: info) { [weak self] task in
                    if let error = task.error, !task.isCancelled {
                        DispatchQueue.main.async {
                            self?.showError("Download failed", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
    }

    override func tableView(_: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            let info = mapsOnDevice[indexPath.row]
            return info.subMaps.isEmpty ? .delete : .none
        }
        return .none
    }

    override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let info = mapsOnDevice[indexPath.row]
            for task in GLMapManager.shared.downloadTasks(forMap: info, dataSets: .all) ?? [] {
                task.cancel()
            }
            GLMapManager.shared.deleteDataSets(.all, forMap: info)
            setMaps(allMaps)
        }
    }
}
