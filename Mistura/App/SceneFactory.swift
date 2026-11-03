import UIKit

protocol SceneFactory {
    func makeSearch(coordinator: SearchCoordinatorDelegate) -> UIViewController
    func makeDetail(for meal: MealSummary,
                    coordinator: DetailCoordinatorDelegate) -> UIViewController
}

final class AppSceneFactory: SceneFactory {
    private let mealRepository: MealRepositoryType
    private let historyRepository: HistoryRepositoryType

    init(mealRepository: MealRepositoryType,
         historyRepository: HistoryRepositoryType) {
        self.mealRepository = mealRepository
        self.historyRepository = historyRepository
    }

    convenience init() {
        self.init(
            mealRepository: RemoteMealRepository(client: URLSessionHTTPClient()),
            historyRepository: CoreDataHistoryRepository(stack: CoreDataStack())
        )
    }

    func makeSearch(coordinator: SearchCoordinatorDelegate) -> UIViewController {
        let presenter = SearchPresenter(mealRepository: mealRepository, historyRepository: historyRepository)
        let viewController = SearchViewController(presenter: presenter)
        presenter.viewController = viewController
        presenter.coordinator = coordinator
        return viewController
    }

    func makeDetail(for meal: MealSummary,
                    coordinator: DetailCoordinatorDelegate) -> UIViewController {
        let presenter = DetailPresenter(meal: meal,
                                        mealRepository: mealRepository,
                                        historyRepository: historyRepository)
        let viewController = DetailViewController(presenter: presenter)
        presenter.viewController = viewController
        presenter.coordinator = coordinator
        return viewController
    }
}
