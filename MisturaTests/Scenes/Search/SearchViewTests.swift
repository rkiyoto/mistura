import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class SearchViewTests: QuickSpec {
    override class func spec() {
        var sut: SearchView!

        let meals = [
            MealCellModel(id: "1",
                          title: "Leblebi Soup",
                          imageURL: nil),
            MealCellModel(id: "2",
                          title: "Beef Banh Mi Bowls with Sriracha Mayo, Carrot & Pickled Cucumber",
                          imageURL: nil)
        ]

        beforeEach {
            sut = SearchView(imageLoader: ImageLoaderStub())
        }

        describe("retry button") {
            it("is visible in the error state") {
                sut.render(.error("Erro"))

                expect(retryButton(in: sut)?.isHidden).to(beFalse())
            }

            it("is hidden in the empty state") {
                sut.render(.empty("Vazio"))

                expect(retryButton(in: sut)?.isHidden).to(beTrue())
            }

            it("is hidden again when leaving the error state") {
                sut.render(.error("Erro"))

                sut.render(.loading)

                expect(retryButton(in: sut)?.isHidden).to(beTrue())
            }

            it("calls onRetry when tapped") {
                var retryCount = 0
                sut.onRetry = { retryCount += 1 }
                sut.render(.error("Erro"))

                retryButton(in: sut)?.simulateTap()

                expect(retryCount).to(equal(1))
            }
        }

        describe("render") {
            it("shows the idle message") {
                sut.render(.idle)

                assertRenderSnapshot(of: sut, named: "idle")
            }

            it("shows the history with its header") {
                sut.render(.history(meals))

                assertRenderSnapshot(of: sut, named: "history")
            }

            it("shows the activity indicator while loading") {
                sut.render(.loading)

                assertRenderSnapshot(of: sut, named: "loading")
            }

            it("shows the results without a header") {
                sut.render(.results(meals))

                assertRenderSnapshot(of: sut, named: "results")
            }

            it("shows the empty message without the retry button") {
                sut.render(.empty(TextStrings.searchEmptyMessage(query: "xyz")))

                assertRenderSnapshot(of: sut, named: "empty")
            }

            it("shows the error message with the retry button") {
                sut.render(.error(TextStrings.searchErrorMessage))

                assertRenderSnapshot(of: sut, named: "error")
            }

            it("removes the list when moving from results to error") {
                sut.render(.results(meals))

                sut.render(.error(TextStrings.searchErrorMessage))

                assertRenderSnapshot(of: sut, named: "results-to-error")
            }

            it("removes the error when moving from error to results") {
                sut.render(.error(TextStrings.searchErrorMessage))

                sut.render(.results(meals))

                assertRenderSnapshot(of: sut, named: "error-to-results")
            }
        }

        describe("table actions") {
            context("when a row is selected") {
                it("calls onSelectItem with the result index") {
                    var selectedIndexes: [Int] = []
                    sut.onSelectItem = { selectedIndexes.append($0) }
                    sut.render(.results(meals))

                    selectRow(at: 1, in: sut)

                    expect(selectedIndexes).to(equal([1]))
                }

                it("calls onSelectItem with the history index") {
                    var selectedIndexes: [Int] = []
                    sut.onSelectItem = { selectedIndexes.append($0) }
                    sut.render(.history(meals))

                    selectRow(at: 0, in: sut)

                    expect(selectedIndexes).to(equal([0]))
                }
            }

            context("when the history header is shown") {
                it("calls onClearHistory once when the clear button is tapped") {
                    var clearCount = 0
                    sut.onClearHistory = { clearCount += 1 }
                    sut.render(.history(meals))

                    let header = headerView(in: sut)

                    header?.firstView(of: UIButton.self)?.simulateTap()

                    expect(clearCount).to(equal(1))
                }
            }

            context("when the results are shown") {
                it("has no header to clear the history") {
                    sut.render(.results(meals))

                    expect(headerView(in: sut)).to(beNil())
                }
            }
        }
    }
}

private func retryButton(in view: UIView) -> UIButton? {
    view.button(titled: TextStrings.retryButton)
}

private func selectRow(at row: Int, in view: UIView) {
    guard let tableView = view.firstView(of: UITableView.self) else { return }
    tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: row, section: 0))
}

private func headerView(in view: UIView) -> UIView? {
    guard let tableView = view.firstView(of: UITableView.self) else { return nil }
    return tableView.delegate?.tableView?(tableView, viewForHeaderInSection: 0)
}
