import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class MealServiceTests: QuickSpec {
    override class func spec() {
        let baseURL = "https://www.themealdb.com/api/json/v1/1"

        describe("searchByName") {
            it("builds the search URL") {
                expect(MealService.searchByName("Soup").url?.absoluteString)
                    .to(equal("\(baseURL)/search.php?s=Soup"))
            }

            it("encodes spaces and accents") {
                expect(MealService.searchByName("Pão de queijo").url?.absoluteString)
                    .to(equal("\(baseURL)/search.php?s=P%C3%A3o%20de%20queijo"))
            }
        }

        describe("filterByIngredient") {
            it("builds the filter URL") {
                expect(MealService.filterByIngredient("rice").url?.absoluteString)
                    .to(equal("\(baseURL)/filter.php?i=rice"))
            }

            it("lowercases the ingredient and replaces spaces with underscores") {
                expect(MealService.filterByIngredient("Chicken Breast").url?.absoluteString)
                    .to(equal("\(baseURL)/filter.php?i=chicken_breast"))
            }
        }

        describe("lookup") {
            it("builds the lookup URL") {
                expect(MealService.lookup(id: "52772").url?.absoluteString)
                    .to(equal("\(baseURL)/lookup.php?i=52772"))
            }
        }
    }
}
