import UIKit

final class SearchTableDataSource: NSObject {
    var onSelectItem: ((Int) -> Void)?
    var onClearHistory: (() -> Void)?

    private let imageLoader: ImageLoaderType

    private var items = [MealCellModel]()
    private var sectionTitle: String?

    init(imageLoader: ImageLoaderType = ImageLoader.shared) {
        self.imageLoader = imageLoader
        super.init()
    }

    func update(items: [MealCellModel], sectionTitle: String?) {
        self.items = items
        self.sectionTitle = sectionTitle
    }
}

// MARK: - UITableViewDataSource

extension SearchTableDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MealCell.reuseIdentifier,
                                                       for: indexPath) as? MealCell else {
            return UITableViewCell()
        }
        cell.configure(with: items[indexPath.row], imageLoader: imageLoader)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SearchTableDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectItem?(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sectionTitle else { return nil }
        
        let headerView = HistoryHeaderView(title: title)
        headerView.onClearHistory = { [weak self] in
            self?.onClearHistory?()
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sectionTitle != nil ? UITableView.automaticDimension : 0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        sectionTitle != nil ? 44 : 0
    }
}
