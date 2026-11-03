@testable import Mistura

final class HistoryRepositoryStub: HistoryRepositoryType {
    var recentMealsResult: Result<[MealSummary], Error> = .success([])
    var saveError: Error?
    var clearError: Error?

    private(set) var savedMeals: [MealSummary] = []
    private(set) var clearCount = 0

    func recentMeals() throws -> [MealSummary] {
        try recentMealsResult.get()
    }

    func save(_ meal: MealSummary) throws {
        if let saveError { throw saveError }
        savedMeals.append(meal)
    }

    func clearHistory() throws {
        clearCount += 1
        if let clearError { throw clearError }
        savedMeals.removeAll()
    }
}
