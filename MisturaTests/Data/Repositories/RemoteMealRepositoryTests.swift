import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class RemoteMealRepositoryTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var client: HTTPClientStub!
        nonisolated(unsafe) var sut: RemoteMealRepository!

        let soupResponse = """
        {
            "meals": [
                {
                    "idMeal": "1",
                    "strMeal": "Soup",
                    "strMealThumb": "https://example.com/soup.jpg"
                }
            ]
        }
        """

        beforeEach { @MainActor in
            client = HTTPClientStub()
            client.result = .success(Data(soupResponse.utf8))
            sut = RemoteMealRepository(client: client)
        }

        describe("searchMeals") {
            it("uses the search endpoint when searching by name") { @MainActor in
                _ = try await sut.searchMeals(query: "soup", type: .name)

                expect(client.requestedURLs).to(equal([MealService.searchByName("soup").url].compactMap { $0 }))
            }

            it("uses the filter endpoint when searching by ingredient") { @MainActor in
                _ = try await sut.searchMeals(query: "rice", type: .ingredient)

                expect(client.requestedURLs).to(equal([MealService.filterByIngredient("rice").url].compactMap { $0 }))
            }

            it("maps the response to summaries") { @MainActor in
                let meals = try await sut.searchMeals(query: "soup", type: .name)

                expect(meals).to(equal([
                    MealSummary(id: "1", name: "Soup", thumbnailURL: URL(string: "https://example.com/soup.jpg/small"))
                ]))
            }

            it("returns an empty list when there are no meals") { @MainActor in
                let emptyResponse = """
                {
                    "meals": null
                }
                """
                client.result = .success(Data(emptyResponse.utf8))

                let meals = try await sut.searchMeals(query: "xyz", type: .name)

                expect(meals).to(beEmpty())
            }

            it("propagates a client failure") { @MainActor in
                client.result = .failure(NetworkError.invalidResponse)

                let error = await captureError { try await sut.searchMeals(query: "soup", type: .name) }

                expect(error).to(matchError(NetworkError.invalidResponse))
            }

            it("wraps an undecodable response in a decoding error") { @MainActor in
                client.result = .success(Data("not json".utf8))

                let error = await captureError { try await sut.searchMeals(query: "soup", type: .name) }

                expect(isDecodingError(error)).to(beTrue())
            }

            it("wraps a malformed meals field in a decoding error") { @MainActor in
                let malformedResponse = """
                {
                    "meals": "invalid"
                }
                """
                client.result = .success(Data(malformedResponse.utf8))

                let error = await captureError { try await sut.searchMeals(query: "soup", type: .name) }

                expect(isDecodingError(error)).to(beTrue())
            }
        }

        describe("mealDetail") {
            it("uses the lookup endpoint") { @MainActor in
                _ = try await sut.mealDetail(id: "1")

                expect(client.requestedURLs).to(equal([MealService.lookup(id: "1").url].compactMap { $0 }))
            }

            it("maps the first meal to a detail") { @MainActor in
                let detail = try await sut.mealDetail(id: "1")

                expect(detail?.id).to(equal("1"))
                expect(detail?.name).to(equal("Soup"))
                expect(detail?.imageURL).to(equal(URL(string: "https://example.com/soup.jpg")))
            }

            it("returns nil when the meal does not exist") { @MainActor in
                let notFoundResponse = """
                {
                    "meals": null
                }
                """
                client.result = .success(Data(notFoundResponse.utf8))

                let detail = try await sut.mealDetail(id: "0")

                expect(detail).to(beNil())
            }

            it("propagates a client failure") { @MainActor in
                client.result = .failure(NetworkError.invalidResponse)

                let error = await captureError { try await sut.mealDetail(id: "1") }

                expect(error).to(matchError(NetworkError.invalidResponse))
            }
        }
    }
}

private func isDecodingError(_ error: Error?) -> Bool {
    guard case .decoding = error as? NetworkError else { return false }
    return true
}
