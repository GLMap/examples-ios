import GLMap
import GLMapSwift
import GLSearch
import UIKit

/// Runs one request against online or offline data and displays the same result objects
/// as map markers and table rows.
class SearchDemo: DemoMapViewController, UISearchResultsUpdating, UISearchBarDelegate,
    UITableViewDataSource, UITableViewDelegate
{
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)

    private var results: [GLMapVectorObject] = []
    private var markerLayer: GLMapMarkerLayer?
    private var selectedResult: GLMapVectorObject?
    private lazy var selectedMarker: GLMapImage? = {
        guard let path = svgPath("pin"),
              let image = GLMapVectorImageFactory.shared.image(
                  fromSvg: path,
                  withScale: 1.4,
                  andTintColor: GLMapColor(red: 230, green: 60, blue: 60, alpha: 255)
              ) else { return nil }

        let marker = GLMapImage(drawOrder: 4)
        marker.setImage(image)
        marker.offset = CGPoint(x: image.size.width / 2, y: 0)
        marker.hidden = true
        return marker
    }()

    private var requestID: Int64 = 0
    private var searchGeneration = 0
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
        if let selectedMarker { map.add(selectedMarker) }
        map.tapGestureBlock = { [weak self] gesture in
            guard let self, let markerLayer else { return }
            var point = map.makeMapPoint(fromDisplay: gesture.location(in: map))

            // Let the marker layer perform screen-space hit-testing. It may return a new
            // Objective-C wrapper for the same native object, so compare by value, not identity.
            guard let marker = markerLayer.objects(at: map, nearPoint: &point, distance: 24)?.first as? GLMapVectorObject,
                  let row = results.firstIndex(where: { $0.isEqual(marker) })
            else { return }

            let indexPath = IndexPath(row: row, section: 0)
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            selectResult(at: indexPath)
        }

        runSearch(type: .search)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pendingSearch?.cancel()
        cancelRunningRequest()
    }

    // MARK: - Setup

    private func setupLayout() {
        map.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            map.topAnchor.constraint(equalTo: view.topAnchor),
            map.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            map.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            map.bottomAnchor.constraint(equalTo: tableView.topAnchor),

            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.heightAnchor.constraint(equalTo: guide.heightAnchor, multiplier: 0.42),
        ])

        // The map renders under the navigation controls, so expose their actual footprint
        // to camera framing and drawable placement.
        map.visibleMapInsetsProvider = { [weak self] in
            guard let self else { return .zero }
            var navigationBarBottom = view.safeAreaInsets.top
            if let navigationBar = navigationController?.navigationBar {
                navigationBarBottom = navigationBar.convert(navigationBar.bounds, to: map).maxY
            }
            return UIEdgeInsets(top: navigationBarBottom + 20, left: 20, bottom: 20, right: 20)
        }
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
        if #available(iOS 16, *) {
            navigationItem.preferredSearchBarPlacement = .stacked
        }
        definesPresentationContext = true
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
        pendingSearch?.cancel()
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
        let generation = searchGeneration
        let completion: (GLMapVectorObjectArray?, Error?) -> Void = { [weak self] results, error in
            guard let self, self.searchGeneration == generation else { return }
            self.handle(results, error, source: source)
        }
        requestID = isOnline ? request.startOnline(completion: completion) : request.startOffline(completion: completion)
    }

    private func cancelRunningRequest() {
        searchGeneration += 1
        if requestID != 0 { GLSearchRequest.cancel(requestID) }
        requestID = 0
    }

    private func handle(_ results: GLMapVectorObjectArray?, _ error: Error?, source: String) {
        requestID = 0
        if let error {
            showAlert("\(source) Search Failed", message: error.localizedDescription)
            return
        }
        selectedMarker?.hidden = true
        selectedResult = nil
        self.results = results?.array() ?? []
        displayMarkers()
        tableView.reloadData()
        title = "\(source): \(self.results.count) results"
    }

    // MARK: - Map markers

    private static let resultColor = GLMapColor(red: 0x00, green: 0x66, blue: 0xCC, alpha: 0xFF)
    private lazy var markerStyles: GLMapMarkerStyleCollection? = {
        guard let imagePath = svgPath("cluster"),
              let image = GLMapVectorImageFactory.shared.image(
                  fromSvg: imagePath,
                  withScale: 0.2,
                  andTintColor: Self.resultColor
              )
        else { return nil }

        let styles = GLMapMarkerStyleCollection()
        styles.addStyle(with: image)
        styles.setMarkerLocationBlock { ($0 as? GLMapVectorObject)?.point ?? GLMapPoint() }
        styles.setMarkerDataFill { _, data in data.setStyle(0) }
        return styles
    }()

    private func displayMarkers() {
        if let markerLayer {
            map.remove(markerLayer)
            self.markerLayer = nil
        }
        guard !results.isEmpty, let markerStyles else { return }

        let layer = GLMapMarkerLayer(markers: results, andStyles: markerStyles, clusteringRadius: 0, drawOrder: 3)
        map.add(layer)
        markerLayer = layer

        var bbox = GLMapBBox.empty
        for obj in results {
            bbox.add(point: obj.point)
        }
        let scale = map.mapScale(for: bbox)
        if scale.isFinite {
            map.mapScale = scale
        } else {
            map.mapZoomLevel = 15
        }

        centerMap(on: bbox.center)
    }

    private func centerMap(on point: GLMapPoint) {
        // Insets constrain the scale but intentionally do not move the camera. Center the
        // requested point explicitly in the unobscured part of the map.
        let insets = map.visibleMapInsets()
        let origin = map.mapOrigin
        let displayOffset = CGPoint(
            x: (insets.right - insets.left) * 0.5 + map.bounds.width * (0.5 - origin.x),
            y: (insets.bottom - insets.top) * 0.5 + map.bounds.height * (0.5 - origin.y)
        )
        let mapOffset = map.makeMapPoint(
            fromDisplayDelta: displayOffset,
            andMapScale: map.mapScale,
            andMapAngle: map.mapAngle
        )
        map.mapCenter = point.add(x: mapOffset.x, y: mapOffset.y)
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
        selectResult(at: indexPath)
    }

    private func selectResult(at indexPath: IndexPath) {
        let result = results[indexPath.row]
        if selectedResult !== result {
            // The layer animates the selected circle out and restores the previous one while
            // the individual image provides a distinct, inexpensive selected state.
            markerLayer?.add(selectedResult.map { [$0] }, remove: [result], animated: true)
            selectedResult = result
            selectedMarker?.position = result.point
            selectedMarker?.scale = 0.01
            selectedMarker?.hidden = false
        }

        map.animate { animation in
            animation.duration = 0.3
            self.selectedMarker?.scale = 1
            self.centerMap(on: result.point)
        }
    }
}
