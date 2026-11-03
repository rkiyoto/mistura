import Foundation

protocol MealRepositoryType {
    func searchMeals(query: String, type: SearchType) async throws -> [MealSummary]
    func mealDetail(id: String) async throws -> MealDetail?
}

final class RemoteMealRepository {
    private let client: HTTPClient
    private let decoder = JSONDecoder()

    init(client: HTTPClient) {
        self.client = client
    }

    private func fetchMeals(_ endpoint: MealService) async throws -> [MealDTO] {
        guard let url = endpoint.url else { throw NetworkError.invalidURL }
        let data = try await client.makeRequest(from: url)
        do {
            return try decoder.decode(MealListResponseDTO.self, from: data).meals ?? []
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}

extension RemoteMealRepository: MealRepositoryType {
    func searchMeals(query: String, type: SearchType) async throws -> [MealSummary] {
        let endpoint: MealService = switch type {
        case .name: .searchByName(query)
        case .ingredient: .filterByIngredient(query)
        }
        return try await fetchMeals(endpoint).map(\.summary)
    }

    func mealDetail(id: String) async throws -> MealDetail? {
        try await fetchMeals(.lookup(id: id)).first?.detail
    }
}
