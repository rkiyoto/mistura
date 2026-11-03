import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class SearchPresenterTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var mealRepository: MealRepositoryStub!
        nonisolated(unsafe) var historyRepository: HistoryRepositoryStub!
        nonisolated(unsafe) var viewController: SearchViewControllerSpy!
        nonisolated(unsafe) var coordinator: SearchCoordinatorSpy!
        nonisolated(unsafe) var debounce: AsyncGate!
        nonisolated(unsafe) var sut: SearchPresenter!

        let soup = MealSummary(id: "1", name: "Soup", thumbnailURL: nil)
        let rice = MealSummary(id: "2", name: "Rice", thumbnailURL: nil)
        let untitled = MealSummary(id: "3", name: "", thumbnailURL: nil)

        beforeEach { @MainActor in
            mealRepository = MealRepositoryStub()
            historyRepository = HistoryRepositoryStub()
            viewController = SearchViewControllerSpy()
            coordinator = SearchCoordinatorSpy()
            debounce = AsyncGate()
            let gate: AsyncGate = debounce
            sut = SearchPresenter(
                mealRepository: mealRepository,
                historyRepository: historyRepository,
                waitForDebounce: { try await gate.wait() }
            )
            sut.viewController = viewController
            sut.coordinator = coordinator
        }

        describe("viewDidLoad") {
            it("renders the idle state") { @MainActor in
                sut.viewDidLoad()

                expect(viewController.renderedStates).to(equal([.idle]))
            }
        }

        describe("searchDidBeginEditing") {
            context("when there is history") {
                it("renders the history") { @MainActor in
                    historyRepository.recentMealsResult = .success([soup])

                    sut.searchDidBeginEditing()

                    expect(viewController.renderedStates).to(equal([.history([MealCellModel(meal: soup)])]))
                }
            }

            context("when the history is empty") {
                it("renders the idle state") { @MainActor in
                    sut.searchDidBeginEditing()

                    expect(viewController.renderedStates).to(equal([.idle]))
                }
            }

            context("when reading the history fails") {
                it("renders the idle state") { @MainActor in
                    historyRepository.recentMealsResult = .failure(TestError.any)

                    sut.searchDidBeginEditing()

                    expect(viewController.renderedStates).to(equal([.idle]))
                }
            }
        }

        describe("viewWillAppear") {
            it("refreshes the history when returning to an empty search") { @MainActor in
                sut.searchDidBeginEditing()
                historyRepository.recentMealsResult = .success([soup])

                sut.viewWillAppear()

                expect(viewController.renderedStates.last).to(equal(.history([MealCellModel(meal: soup)])))
            }

            it("renders nothing when the search is not being edited") { @MainActor in
                sut.viewWillAppear()

                expect(viewController.renderedStates).to(beEmpty())
            }
        }

        describe("searchTextDidChange") {
            context("when the search succeeds") {
                it("renders loading followed by the results") { @MainActor in
                    mealRepository.searchResult = .success([soup, rice])

                    sut.searchTextDidChange("so")

                    await expect { @MainActor in viewController.renderedStates }.toEventually(equal([
                        .loading,
                        .results([MealCellModel(meal: soup), MealCellModel(meal: rice)])
                    ]))
                }

                it("searches by name by default") { @MainActor in
                    sut.searchTextDidChange("soup")

                    await expect { @MainActor in mealRepository.searches }.toEventually(equal([
                        MealRepositoryStub.Search(query: "soup", type: .name)
                    ]))
                }

                it("trims the query") { @MainActor in
                    sut.searchTextDidChange("  soup ")

                    await expect { @MainActor in mealRepository.searches.first?.query }.toEventually(equal("soup"))
                }
            }

            context("when there are no results") {
                it("renders the empty state with the query") { @MainActor in
                    sut.searchTextDidChange("xyz")

                    await expect { @MainActor in viewController.renderedStates.last }
                        .toEventually(equal(.empty(TextStrings.searchEmptyMessage(query: "xyz"))))
                }
            }

            context("when a meal has no title") {
                it("hides it from the results") { @MainActor in
                    mealRepository.searchResult = .success([untitled, rice])

                    sut.searchTextDidChange("rice")

                    await expect { @MainActor in viewController.renderedStates.last }
                        .toEventually(equal(.results([MealCellModel(meal: rice)])))
                }

                it("renders the empty state when no meal has a title") { @MainActor in
                    mealRepository.searchResult = .success([untitled])

                    sut.searchTextDidChange("xyz")

                    await expect { @MainActor in viewController.renderedStates.last }
                        .toEventually(equal(.empty(TextStrings.searchEmptyMessage(query: "xyz"))))
                }
            }

            context("when the search fails") {
                it("renders the error state") { @MainActor in
                    mealRepository.searchResult = .failure(TestError.any)

                    sut.searchTextDidChange("soup")

                    await expect { @MainActor in viewController.renderedStates.last }
                        .toEventually(equal(.error(TextStrings.searchErrorMessage)))
                }
            }

            context("while the debounce has not finished") {
                it("does not search or render anything") { @MainActor in
                    debounce.isHeld = true

                    sut.searchTextDidChange("soup")
                    await expect { @MainActor in debounce.waitCount }.toEventually(equal(1))

                    expect(mealRepository.searches).to(beEmpty())
                    expect(viewController.renderedStates).to(beEmpty())
                }

                it("searches once the debounce finishes") { @MainActor in
                    debounce.isHeld = true
                    sut.searchTextDidChange("soup")
                    await expect { @MainActor in debounce.waitCount }.toEventually(equal(1))

                    debounce.release()

                    await expect { @MainActor in mealRepository.searches.map(\.query) }
                        .toEventually(equal(["soup"]))
                }
            }

            context("when the user keeps typing") {
                it("only searches the last text") { @MainActor in
                    debounce.isHeld = true

                    sut.searchTextDidChange("s")
                    sut.searchTextDidChange("so")
                    sut.searchTextDidChange("soup")
                    await expect { @MainActor in debounce.cancelledCount }.toEventually(equal(2))
                    await expect { @MainActor in debounce.waitCount }.toEventually(equal(3))
                    debounce.release()

                    await expect { @MainActor in mealRepository.searches.map(\.query) }
                        .toEventually(equal(["soup"]))
                }
            }

            context("when the text is cleared") {
                it("cancels the pending search and shows the history") { @MainActor in
                    debounce.isHeld = true
                    historyRepository.recentMealsResult = .success([soup])
                    sut.searchDidBeginEditing()

                    sut.searchTextDidChange("rice")
                    sut.searchTextDidChange("")

                    await expect { @MainActor in debounce.cancelledCount }.toEventually(equal(1))
                    expect(mealRepository.searches).to(beEmpty())
                    expect(viewController.renderedStates.last).to(equal(.history([MealCellModel(meal: soup)])))
                }
            }
        }

        describe("searchTypeDidChange") {
            it("searches right away with the new type, without waiting for the debounce") { @MainActor in
                debounce.isHeld = true
                sut.searchTextDidChange("rice")

                sut.searchTypeDidChange(.ingredient)

                await expect { @MainActor in mealRepository.searches }.toEventually(equal([
                    MealRepositoryStub.Search(query: "rice", type: .ingredient)
                ]))
            }

            it("does not search when the query is empty") { @MainActor in
                sut.searchTypeDidChange(.ingredient)

                expect(viewController.renderedStates).to(equal([.idle]))
                expect(mealRepository.searches).to(beEmpty())
            }
        }

        describe("searchDidCancel") {
            it("cancels the pending search and renders the idle state") { @MainActor in
                debounce.isHeld = true
                sut.searchTextDidChange("rice")

                sut.searchDidCancel()

                await expect { @MainActor in debounce.cancelledCount }.toEventually(equal(1))
                expect(mealRepository.searches).to(beEmpty())
                expect(viewController.renderedStates).to(equal([.idle]))
            }
        }

        describe("didTapRetry") {
            it("repeats the failed search and renders the results") { @MainActor in
                mealRepository.searchResult = .failure(TestError.any)
                sut.searchTypeDidChange(.ingredient)
                sut.searchTextDidChange("rice")
                await expect { @MainActor in viewController.renderedStates.last }
                    .toEventually(equal(.error(TextStrings.searchErrorMessage)))
                mealRepository.searchResult = .success([rice])

                sut.didTapRetry()

                await expect { @MainActor in viewController.renderedStates.last }
                    .toEventually(equal(.results([MealCellModel(meal: rice)])))
                let search = MealRepositoryStub.Search(query: "rice", type: .ingredient)
                expect(mealRepository.searches).to(equal([search, search]))
            }
        }

        describe("didTapClearHistory") {
            context("when clearing succeeds") {
                it("clears the history and renders the idle state") { @MainActor in
                    historyRepository.recentMealsResult = .success([soup])
                    sut.searchDidBeginEditing()

                    sut.didTapClearHistory()

                    expect(historyRepository.clearCount).to(equal(1))
                    expect(viewController.renderedStates.last).to(equal(.idle))
                }

                it("no longer selects the cleared meals") { @MainActor in
                    historyRepository.recentMealsResult = .success([soup])
                    sut.searchDidBeginEditing()

                    sut.didTapClearHistory()
                    sut.didSelectItem(at: 0)

                    expect(coordinator.shownMeals).to(beEmpty())
                }
            }

            context("when clearing fails") {
                it("keeps the history on screen") { @MainActor in
                    historyRepository.recentMealsResult = .success([soup])
                    historyRepository.clearError = TestError.any
                    sut.searchDidBeginEditing()

                    sut.didTapClearHistory()

                    expect(viewController.renderedStates).to(equal([.history([MealCellModel(meal: soup)])]))
                }

                it("keeps the meals selectable") { @MainActor in
                    historyRepository.recentMealsResult = .success([soup])
                    historyRepository.clearError = TestError.any
                    sut.searchDidBeginEditing()

                    sut.didTapClearHistory()
                    sut.didSelectItem(at: 0)

                    expect(coordinator.shownMeals).to(equal([soup]))
                }
            }
        }

        describe("didSelectItem") {
            context("when a search result is selected") {
                it("shows its detail") { @MainActor in
                    mealRepository.searchResult = .success([soup, rice])
                    sut.searchTextDidChange("so")
                    await expect { @MainActor in viewController.renderedStates.count }.toEventually(equal(2))

                    sut.didSelectItem(at: 1)

                    expect(coordinator.shownMeals).to(equal([rice]))
                }
            }

            context("when an untitled meal was hidden from the results") {
                it("shows the detail of the visible meal") { @MainActor in
                    mealRepository.searchResult = .success([untitled, rice])
                    sut.searchTextDidChange("rice")
                    await expect { @MainActor in viewController.renderedStates.count }.toEventually(equal(2))

                    sut.didSelectItem(at: 0)

                    expect(coordinator.shownMeals).to(equal([rice]))
                }
            }

            context("when a history item is selected") {
                it("shows its detail") { @MainActor in
                    historyRepository.recentMealsResult = .success([soup])
                    sut.searchDidBeginEditing()

                    sut.didSelectItem(at: 0)

                    expect(coordinator.shownMeals).to(equal([soup]))
                }
            }

            context("when the index is out of bounds") {
                it("does not navigate") { @MainActor in
                    sut.didSelectItem(at: 5)

                    expect(coordinator.shownMeals).to(beEmpty())
                }
            }
        }

        describe("memory management") {
            it("does not retain the view controller or the coordinator") { @MainActor in
                weak let weakViewController = viewController
                weak let weakCoordinator = coordinator

                viewController = nil
                coordinator = nil

                expect(weakViewController).to(beNil())
                expect(weakCoordinator).to(beNil())
            }

            it("cancels the pending debounce on deinit") { @MainActor in
                debounce.isHeld = true
                sut.searchTextDidChange("rice")
                await expect { @MainActor in debounce.waitCount }.toEventually(equal(1))

                sut = nil

                await expect { @MainActor in debounce.cancelledCount }.toEventually(equal(1))
                expect(mealRepository.searches).to(beEmpty())
            }

            it("cancels the ongoing search on deinit") { @MainActor in
                let searchGate = AsyncGate()
                searchGate.isHeld = true
                mealRepository.searchGate = searchGate
                sut.searchTypeDidChange(.name)
                sut.searchTextDidChange("rice")
                await expect { @MainActor in searchGate.waitCount }.toEventually(equal(1))

                sut = nil

                await expect { @MainActor in searchGate.cancelledCount }.toEventually(equal(1))
                expect(viewController.renderedStates.last).to(equal(.loading))
            }
        }
    }
}
