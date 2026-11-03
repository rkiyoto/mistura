import Foundation
@testable import Mistura

final class DetailPresenterSpy: DetailPresenterType {
    private(set) var viewDidLoadCount = 0
    private(set) var retryCount = 0
    private(set) var videoTapCount = 0
    private(set) var shoppingCartIngredients: [[String]] = []

    func viewDidLoad() {
        viewDidLoadCount += 1
    }

    func didTapRetry() {
        retryCount += 1
    }

    func didTapVideo() {
        videoTapCount += 1
    }

    func didTapShoppingCart(ingredients: [String]) {
        shoppingCartIngredients.append(ingredients)
    }
}
