import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class CoreDataHistoryRepositoryTests: QuickSpec {
    override class func spec() {
        var stack: CoreDataStack!
        var clock: Date!
        var sut: CoreDataHistoryRepository!

        let soup = MealSummary(id: "1", name: "Soup", thumbnailURL: URL(string: "https://example.com/soup.jpg/small"))
        let rice = MealSummary(id: "2", name: "Rice", thumbnailURL: nil)
        let bread = MealSummary(id: "3", name: "Bread", thumbnailURL: nil)
        let salad = MealSummary(id: "4", name: "Salad", thumbnailURL: nil)

        beforeEach {
            stack = CoreDataStack(inMemory: true)
            clock = Date(timeIntervalSince1970: 0)
            // Cada chamada avança o relógio, para que a ordem dos itens seja determinística
            sut = CoreDataHistoryRepository(stack: stack, limit: 3, now: {
                clock = clock.addingTimeInterval(1)
                return clock
            })
        }

        describe("recentMeals") {
            it("is empty before anything is saved") {
                expect(try sut.recentMeals()).to(beEmpty())
            }

            it("returns the most recent meal first") {
                try sut.save(soup)
                try sut.save(rice)

                expect(try sut.recentMeals()).to(equal([rice, soup]))
            }
        }

        describe("save") {
            it("keeps the name and the thumbnail") {
                try sut.save(soup)

                let saved = try sut.recentMeals().first

                expect(saved?.name).to(equal("Soup"))
                expect(saved?.thumbnailURL).to(equal(URL(string: "https://example.com/soup.jpg/small")))
            }

            it("accepts a meal without a thumbnail") {
                let meal = MealSummary(id: "9", name: "Plain", thumbnailURL: nil)

                try sut.save(meal)

                expect(try sut.recentMeals()).to(equal([meal]))
            }

            it("does not duplicate a meal and moves it to the top") {
                try sut.save(soup)
                try sut.save(rice)

                try sut.save(soup)

                expect(try sut.recentMeals()).to(equal([soup, rice]))
            }

            it("updates the data of a meal that was already saved") {
                try sut.save(soup)
                let renamed = MealSummary(id: soup.id, name: "Tomato Soup", thumbnailURL: nil)

                try sut.save(renamed)

                expect(try sut.recentMeals()).to(equal([renamed]))
            }

            it("removes the oldest meal when the limit is exceeded") {
                try sut.save(soup)
                try sut.save(rice)
                try sut.save(bread)

                try sut.save(salad)

                expect(try sut.recentMeals()).to(equal([salad, bread, rice]))
            }

            it("deletes the meals beyond the limit from the store") {
                try sut.save(soup)
                try sut.save(rice)
                try sut.save(bread)

                try sut.save(salad)

                // Um limite maior na leitura mostra o que de fato ficou gravado
                let otherRepository = CoreDataHistoryRepository(stack: stack, limit: 10)
                expect(try otherRepository.recentMeals()).to(haveCount(3))
            }

            it("keeps the meals available to another repository on the same stack") {
                try sut.save(soup)

                let otherRepository = CoreDataHistoryRepository(stack: stack)

                expect(try otherRepository.recentMeals()).to(equal([soup]))
            }
        }

        describe("clearHistory") {
            it("removes every meal") {
                try sut.save(soup)
                try sut.save(rice)

                try sut.clearHistory()

                expect(try sut.recentMeals()).to(beEmpty())
            }

            it("does nothing when the history is already empty") {
                expect { try sut.clearHistory() }.toNot(throwError())
            }

            it("allows saving the same meal again") {
                try sut.save(soup)
                try sut.clearHistory()

                try sut.save(soup)

                expect(try sut.recentMeals()).to(equal([soup]))
            }
        }
    }
}
