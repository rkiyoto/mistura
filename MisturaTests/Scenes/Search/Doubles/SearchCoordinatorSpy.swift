import Foundation
@testable import Mistura

final class SearchCoordinatorSpy: SearchCoordinatorDelegate {
    private(set) var shownMeals: [MealSummary] = []

    func showDetail(for meal: MealSummary) {
        shownMeals.append(meal)
    }
}
