@testable import Mistura

final class MealRepositoryStub: MealRepositoryType {
    var searchResult: Result<[MealSummary], Error> = .success([])
    var detailResult: Result<MealDetail?, Error> = .success(nil)
    var searchGate: AsyncGate?
    var detailGate: AsyncGate?

    private(set) var searches: [Search] = []

    struct Search: Equatable {
        let query: String
        let type: SearchType
    }

    func searchMeals(query: String, type: SearchType) async throws -> [MealSummary] {
        searches.append(Search(query: query, type: type))
        try await searchGate?.wait()
        return try searchResult.get()
    }

    func mealDetail(id: String) async throws -> MealDetail? {
        try await detailGate?.wait()
        return try detailResult.get()
    }
}
