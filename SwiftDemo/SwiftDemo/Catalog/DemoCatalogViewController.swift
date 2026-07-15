import UIKit

class DemoCatalogViewController: UITableViewController {
    private let groupedDemos = DemoRegistry.groupedDemos

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "GLMap 2.0"
        view.backgroundColor = Theme.backgroundColor

        tableView.register(DemoCatalogCell.self, forCellReuseIdentifier: DemoCatalogCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Theme.cellPadding + Theme.iconSize + 12, bottom: 0, right: 0)
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        groupedDemos.count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        groupedDemos[section].category.rawValue
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedDemos[section].demos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DemoCatalogCell.reuseID, for: indexPath) as! DemoCatalogCell
        let demo = groupedDemos[indexPath.section].demos[indexPath.row]
        cell.configure(with: demo)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let demo = groupedDemos[indexPath.section].demos[indexPath.row]
        let vc = demo.makeViewController()
        vc.title = demo.title
        navigationController?.pushViewController(vc, animated: true)
    }
}
