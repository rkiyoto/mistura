import UIKit

final class DetailViewController: UIViewController {
    private let presenter: DetailPresenterType
    private let contentView: DetailViewType

    // MARK: - Init

    init(presenter: DetailPresenterType,
         contentView: DetailViewType = DetailView()) {
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
        navigationItem.largeTitleDisplayMode = .never
        bindActions()
        presenter.viewDidLoad()
    }

    private func bindActions() {
        contentView.onRetry = { [weak self] in
            self?.presenter.didTapRetry()
        }
        contentView.onVideoTap = { [weak self] in
            self?.presenter.didTapVideo()
        }
        contentView.onShoppingCartTap = { [weak self] ingredients in
            self?.presenter.didTapShoppingCart(ingredients: ingredients)
        }
    }
}

// MARK: - DetailViewControllerType

extension DetailViewController: DetailViewControllerType {
    func display(title: String) {
        self.title = title
    }

    func render(_ state: DetailViewState) {
        contentView.render(state)
    }
}
