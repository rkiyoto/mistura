import UIKit

protocol Coordinator: AnyObject {
    func start()
}

final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private let navigationController: UINavigationController
    private let factory: SceneFactory

    init(
        window: UIWindow,
        factory: SceneFactory,
        navigationController: UINavigationController = UINavigationController()
    ) {
        self.window = window
        self.factory = factory
        self.navigationController = navigationController
    }

    func start() {
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.setViewControllers([factory.makeSearch(coordinator: self)], animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

// MARK: - SearchCoordinatorDelegate

extension AppCoordinator: SearchCoordinatorDelegate {
    func showDetail(for meal: MealSummary) {
        let detail = factory.makeDetail(for: meal, coordinator: self)
        navigationController.pushViewController(detail, animated: true)
    }
}

// MARK: - DetailCoordinatorDelegate

extension AppCoordinator: DetailCoordinatorDelegate {
    func openExternalLink(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
