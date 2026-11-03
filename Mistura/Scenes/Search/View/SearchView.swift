import UIKit

final class SearchView: UIView {
    // MARK: - Actions

    var onSelectItem: ((Int) -> Void)?
    var onRetry: (() -> Void)?
    var onClearHistory: (() -> Void)?

    // MARK: - Dependencies

    private let tableDataSource: SearchTableDataSource

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(MealCell.self, forCellReuseIdentifier: MealCell.reuseIdentifier)
        tableView.dataSource = tableDataSource
        tableView.delegate = tableDataSource
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = TextStrings.retryButton
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.onRetry?()
        })
        button.isHidden = true
        return button
    }()

    private lazy var messageStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Init

    init(imageLoader: ImageLoaderType = ImageLoader.shared) {
        tableDataSource = SearchTableDataSource(imageLoader: imageLoader)
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update(items: [MealCellModel], sectionTitle: String?) {
        tableDataSource.update(items: items, sectionTitle: sectionTitle)
        tableView.reloadData()
    }

    private func handleIdleState() {
        update(items: [], sectionTitle: nil)
        messageLabel.text = TextStrings.searchIdle
        messageLabel.isHidden = false
        activityIndicator.stopAnimating()
    }

    private func handleHistoryState(items: [MealCellModel]) {
        update(items: items, sectionTitle: TextStrings.historySectionTitle)
        messageLabel.text = nil
        messageLabel.isHidden = true
        activityIndicator.stopAnimating()
    }

    private func handleLoadingState() {
        update(items: [], sectionTitle: nil)
        messageLabel.text = nil
        messageLabel.isHidden = true
        activityIndicator.startAnimating()
    }

    private func handleEmptyState(message: String?) {
        update(items: [], sectionTitle: nil)
        messageLabel.text = message
        messageLabel.isHidden = false
        activityIndicator.stopAnimating()
    }

    private func handleErrorState(message: String) {
        handleEmptyState(message: message)
        retryButton.isHidden = false
    }

    private func handleResultListState(results: [MealCellModel]) {
        update(items: results, sectionTitle: nil)
        messageLabel.text = nil
        messageLabel.isHidden = true
        activityIndicator.stopAnimating()
    }
}

// MARK: - SearchViewType

extension SearchView: SearchViewType {
    func render(_ state: SearchViewState) {
        retryButton.isHidden = true

        switch state {
        case .idle:
            handleIdleState()

        case .history(let history):
            handleHistoryState(items: history)

        case .loading:
            handleLoadingState()

        case .results(let results):
            handleResultListState(results: results)

        case .empty(let text):
            handleEmptyState(message: text)

        case .error(let text):
            handleErrorState(message: text)
        }
    }
}

// MARK: - ViewCode
extension SearchView: ViewCodeProtocol {
    func buildViewHierarchy() {
        addSubview(tableView)
        addSubview(messageStack)
        addSubview(activityIndicator)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),

            messageStack.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            messageStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            messageStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    func setupAdditionalConfiguration() {
        backgroundColor = .systemBackground
        tableDataSource.onSelectItem = { [weak self] index in
            self?.onSelectItem?(index)
        }
        tableDataSource.onClearHistory = { [weak self] in
            self?.onClearHistory?()
        }
    }
}
