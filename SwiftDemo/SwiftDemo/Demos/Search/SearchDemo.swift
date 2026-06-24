import GLMap
import GLMapSwift
import GLSearch
import UIKit

/// One `GLSearchRequest`, one result set, two presentations. The same
/// `GLMapVectorObjectArray` returned by `startOnline` / `startOffline` feeds both a
/// `GLMapMarkerLayer` on the map and the rows of a `UITableView` below it — reading
/// `localizedName`, `searchSecondaryText` and `point` from each result object. The two
/// views are linked: tap a row to fly the map to that result, tap a marker to select
/// its row. The search bar's scope switches the transport (Online = server data,
/// Offline = downloaded maps); the request, ranking and display are identical.
class SearchDemo: DemoMapViewController, UISearchResultsUpdating, UISearchBarDelegate,
    UITableViewDataSource, UITableViewDelegate
{
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)

    private var results: [GLMapVectorObject] = []
    private var markerLayer: GLMapMarkerLayer?
    private var selectedPin: GLMapImage?
    private var selectedIndex: Int?

    private var requestID: Int64 = 0
    private var pendingSearch: DispatchWorkItem?

    /// Podgorica — inside the bundled Montenegro offline map, so `startOffline` has data.
    private let center = GLMapGeoPoint(lat: 42.4341, lon: 19.26)

    private var isOnline: Bool {
        searchController.searchBar.selectedScopeButtonIndex == 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Search"

        GLMapManager.shared.tileDownloadingAllowed = true
        // Load an offline map so the offline path has something to search.
        if let offlineMapPath = Bundle.main.path(forResource: "Montenegro", ofType: "vm") {
            GLMapManager.shared.add(.map, path: offlineMapPath, bbox: .empty)
        }

        map.mapGeoCenter = center
        map.mapZoomLevel = 12

        setupLayout()
        setupSearchController()
        setupMapTap()

        runSearch(type: .search)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelRunningRequest()
    }

    // MARK: - Setup

    private func setupLayout() {
        // The base class adds `map` full-screen; re-lay it out as the top ~58% and
        // put the results table underneath.
        map.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: guide.topAnchor),
            map.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            map.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            map.heightAnchor.constraint(equalTo: guide.heightAnchor, multiplier: 0.58),

            tableView.topAnchor.constraint(equalTo: map.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Inset the visible viewport so fitting results (mapScale(for:)/mapCenter) keeps a margin
        // and edge markers aren't clipped at the map borders.
        map.visibleMapInsetsProvider = { UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20) }
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search places (empty = nearby restaurants)"
        searchController.searchBar.scopeButtonTitles = ["Online", "Offline"]
        searchController.searchBar.showsScopeBar = true
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupMapTap() {
        // Tap a marker on the map → select the matching row.
        map.tapGestureBlock = { [weak self] gesture in
            guard let self else { return }
            let tapPt = gesture.location(in: self.map)
            var bestIndex: Int?
            var bestDist = 30.0 * 30.0 // points, squared
            for (i, obj) in self.results.enumerated() {
                let p = self.map.makeDisplayPoint(from: obj.point)
                let dx = Double(p.x - tapPt.x), dy = Double(p.y - tapPt.y)
                let d = dx * dx + dy * dy
                if d < bestDist {
                    bestDist = d
                    bestIndex = i
                }
            }
            if let bestIndex {
                self.select(index: bestIndex, scrollTable: true, moveMap: false)
            }
        }
    }

    // MARK: - Search

    func updateSearchResults(for _: UISearchController) {
        // Debounced search-as-you-type using autocomplete.
        pendingSearch?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.runSearch(type: .autocomplete) }
        pendingSearch = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func searchBarSearchButtonClicked(_: UISearchBar) {
        pendingSearch?.cancel()
        runSearch(type: .search)
    }

    func searchBar(_: UISearchBar, selectedScopeButtonIndexDidChange _: Int) {
        runSearch(type: .search)
    }

    private func runSearch(type: GLSearchRequestType) {
        cancelRunningRequest()
        let text = searchController.searchBar.text ?? ""
        // With text → free-text search; empty → showcase a category browse near center.
        let categories: [String]? = text.isEmpty ? ["restaurant"] : nil

        let request = GLSearchRequest(
            type: type,
            text: text,
            center: center,
            limit: 50,
            locales: ["en", "native"],
            categories: categories
        )

        let source = isOnline ? "Online" : "Offline"
        let completion: (GLMapVectorObjectArray?, Error?) -> Void = { [weak self] results, error in
            self?.handle(results, error, source: source)
        }
        requestID = isOnline ? request.startOnline(completion: completion) : request.startOffline(completion: completion)
        if requestID == 0 {
            showAlert(message: "Search request was not started.")
        }
    }

    private func cancelRunningRequest() {
        guard requestID != 0 else { return }
        GLSearchRequest.cancel(requestID)
        requestID = 0
    }

    private func handle(_ results: GLMapVectorObjectArray?, _ error: Error?, source: String) {
        requestID = 0
        if let error {
            showAlert("\(source) Search Failed", message: error.localizedDescription)
            return
        }
        self.results = results?.array() ?? []
        displayMarkers()
        tableView.reloadData()
        clearSelection()
        title = "\(source): \(self.results.count) results"
    }

    // MARK: - Map markers

    // Results render the same way regardless of transport (online and offline share one engine
    // and one display), so markers use a single color; only the selection is highlighted.
    private static let resultColor = GLMapColor(red: 0x00, green: 0x66, blue: 0xCC, alpha: 0xFF)
    private static let selectedColor = GLMapColor(red: 0xFF, green: 0x99, blue: 0x00, alpha: 0xFF)

    private func displayMarkers() {
        if let markerLayer {
            map.remove(markerLayer)
            self.markerLayer = nil
        }
        guard !results.isEmpty,
              let imagePath = svgPath("cluster"),
              let image = GLMapVectorImageFactory.shared.image(
                  fromSvg: imagePath,
                  withScale: 0.2,
                  andTintColor: Self.resultColor
              )
        else { return }

        let styles = GLMapMarkerStyleCollection()
        styles.addStyle(with: image)
        styles.setMarkerLocationBlock { ($0 as? GLMapVectorObject)?.point ?? GLMapPoint() }
        styles.setMarkerDataFill { _, data in data.setStyle(0) }

        let layer = GLMapMarkerLayer(markers: results, andStyles: styles, clusteringRadius: 0, drawOrder: 3)
        map.add(layer)
        markerLayer = layer

        var bbox = GLMapBBox.empty
        for obj in results {
            bbox.add(point: obj.point)
        }
        map.mapCenter = bbox.center
        map.mapScale = map.mapScale(for: bbox)
    }

    // MARK: - Selection (links table ↔ map)

    private func select(index: Int, scrollTable: Bool, moveMap: Bool) {
        guard results.indices.contains(index) else { return }
        selectedIndex = index
        let obj = results[index]

        // Highlight on the map with a pin overlay on top of the markers.
        if selectedPin == nil, let imagePath = svgPath("cluster"),
           let image = GLMapVectorImageFactory.shared.image(
               fromSvg: imagePath, withScale: 0.32, andTintColor: Self.selectedColor
           )
        {
            let pin = GLMapImage(drawOrder: 4)
            pin.setImage(image)
            // Anchor the pin at its center, matching the marker style's default offset.
            pin.offset = CGPoint(x: image.size.width / 2, y: image.size.height / 2)
            map.add(pin)
            selectedPin = pin
        }
        selectedPin?.position = obj.point

        if moveMap { map.mapCenter = obj.point }
        if scrollTable {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .middle)
        }
    }

    private func clearSelection() {
        selectedIndex = nil
        if let selectedPin {
            map.remove(selectedPin)
            self.selectedPin = nil
        }
        if let sel = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: sel, animated: false)
        }
    }

    // MARK: - UITableView

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let obj = results[indexPath.row]

        var config = cell.defaultContentConfiguration()
        // The search engine bakes match ranges into the value — render them highlighted.
        let normal: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.label]
        let highlight: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.systemBlue]
        if let name = obj.localizedName(map.localeSettings),
           let attributed = name.asAttributedString(normal, highlight: highlight)
        {
            config.attributedText = attributed
        } else {
            config.text = "Unnamed"
        }
        config.secondaryText = obj.searchSecondaryText?.asString()
        cell.contentConfiguration = config
        return cell
    }

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Tap a row → fly the map to that result.
        select(index: indexPath.row, scrollTable: false, moveMap: true)
    }
}
