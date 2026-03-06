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

        let headerView = makeDemoModeHeader()
        tableView.tableHeaderView = headerView
    }

    // MARK: - Demo Mode header

    private func makeDemoModeHeader() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 72))

        let button = UIButton(type: .system)
        button.setTitle("  Demo Mode", for: .normal)
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.tintColor = .white
        button.backgroundColor = Theme.tintColor
        button.layer.cornerRadius = Theme.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openDemoMode), for: .touchUpInside)
        container.addSubview(button)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Theme.cellPadding),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Theme.cellPadding),
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        return container
    }

    @objc private func openDemoMode() {
        let vc = DemoModeViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
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
