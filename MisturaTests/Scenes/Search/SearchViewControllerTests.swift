import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class SearchViewControllerTests: QuickSpec {
    override class func spec() {
        var presenter: SearchPresenterSpy!
        var contentView: SearchViewSpy!
        var sut: SearchViewController!

        beforeEach {
            presenter = SearchPresenterSpy()
            contentView = SearchViewSpy()
            sut = SearchViewController(presenter: presenter, contentView: contentView)
        }

        describe("lifecycle") {
            it("uses the injected content view") {
                expect(sut.view).to(beIdenticalTo(contentView))
            }

            it("notifies the presenter when the view loads") {
                sut.loadViewIfNeeded()

                expect(presenter.viewDidLoadCount).to(equal(1))
            }

            it("notifies the presenter when the view appears") {
                sut.loadViewIfNeeded()

                sut.viewWillAppear(false)

                expect(presenter.viewWillAppearCount).to(equal(1))
            }
        }

        describe("navigation") {
            beforeEach {
                sut.loadViewIfNeeded()
            }

            it("shows the app title") {
                expect(sut.title).to(equal(TextStrings.appTitle))
            }

            it("keeps the search bar visible while scrolling") {
                expect(sut.navigationItem.hidesSearchBarWhenScrolling).to(beFalse())
            }

            it("configures the search bar") {
                let searchBar = sut.navigationItem.searchController?.searchBar

                expect(searchBar?.placeholder).to(equal(TextStrings.searchPlaceholder))
                expect(searchBar?.scopeButtonTitles).to(equal([
                    TextStrings.searchTypeName,
                    TextStrings.searchTypeIngredient
                ]))
            }
        }

        describe("view actions") {
            beforeEach {
                sut.loadViewIfNeeded()
            }

            it("forwards the selected item") {
                contentView.onSelectItem?(2)

                expect(presenter.selectedIndexes).to(equal([2]))
            }

            it("forwards the retry") {
                contentView.onRetry?()

                expect(presenter.retryCount).to(equal(1))
            }

            it("forwards the clear history") {
                contentView.onClearHistory?()

                expect(presenter.clearHistoryCount).to(equal(1))
            }

            it("does not retain the view controller in the actions") {
                weak let weakSUT = sut

                sut = nil

                expect(weakSUT).to(beNil())
            }
        }

        describe("render") {
            it("forwards the state to the content view") {
                sut.render(.loading)

                expect(contentView.renderedStates).to(equal([.loading]))
            }
        }

        describe("search bar") {
            var searchBar: UISearchBar!

            beforeEach {
                sut.loadViewIfNeeded()
                searchBar = sut.navigationItem.searchController?.searchBar
            }

            it("forwards the beginning of the editing") {
                sut.searchBarTextDidBeginEditing(searchBar)

                expect(presenter.beginEditingCount).to(equal(1))
            }

            it("forwards the text") {
                sut.searchBar(searchBar, textDidChange: "soup")

                expect(presenter.searchTexts).to(equal(["soup"]))
            }

            it("forwards the cancellation") {
                sut.searchBarCancelButtonClicked(searchBar)

                expect(presenter.cancelCount).to(equal(1))
            }

            it("converts each scope index to a search type") {
                sut.searchBar(searchBar, selectedScopeButtonIndexDidChange: 1)
                sut.searchBar(searchBar, selectedScopeButtonIndexDidChange: 0)

                expect(presenter.searchTypes).to(equal([.ingredient, .name]))
            }

            it("ignores a scope index out of bounds") {
                sut.searchBar(searchBar, selectedScopeButtonIndexDidChange: 2)

                expect(presenter.searchTypes).to(beEmpty())
            }
        }
    }
}
