import UIKit

final class SearchViewController: UIViewController {
    private let presenter: SearchPresenterType
    private let contentView: SearchViewType

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = TextStrings.searchPlaceholder
        controller.searchBar.scopeButtonTitles = SearchType.allCases.map(\.title)
        controller.searchBar.autocapitalizationType = .none
        controller.searchBar.delegate = self
        return controller
    }()

    // MARK: - Init

    init(presenter: SearchPresenterType,
         contentView: SearchViewType = SearchView()) {
        self.presenter = presenter
        self.contentView = contentView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        presenter.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }

    // MARK: - Setup

    private func setup() {
        setupNavigation()
        bindActions()
    }

    private func setupNavigation() {
        title = TextStrings.appTitle
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func bindActions() {
        contentView.onSelectItem = { [weak self] index in
            self?.presenter.didSelectItem(at: index)
        }
        contentView.onRetry = { [weak self] in
            self?.presenter.didTapRetry()
        }
        contentView.onClearHistory = { [weak self] in
            self?.presenter.didTapClearHistory()
        }
    }
}

// MARK: - SearchViewControllerType

extension SearchViewController: SearchViewControllerType {
    func render(_ state: SearchViewState) {
        contentView.render(state)
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        presenter.searchDidBeginEditing()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.searchTextDidChange(searchText)
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard SearchType.allCases.indices.contains(selectedScope) else { return }
        presenter.searchTypeDidChange(SearchType.allCases[selectedScope])
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        presenter.searchDidCancel()
    }
}
