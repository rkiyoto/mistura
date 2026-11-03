import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class DetailViewControllerTests: QuickSpec {
    override class func spec() {
        var presenter: DetailPresenterSpy!
        var contentView: DetailViewSpy!
        var sut: DetailViewController!

        beforeEach {
            presenter = DetailPresenterSpy()
            contentView = DetailViewSpy()
            sut = DetailViewController(presenter: presenter, contentView: contentView)
        }

        describe("lifecycle") {
            it("uses the injected content view") {
                expect(sut.view).to(beIdenticalTo(contentView))
            }

            it("notifies the presenter when the view loads") {
                sut.loadViewIfNeeded()

                expect(presenter.viewDidLoadCount).to(equal(1))
            }

            it("does not use a large title") {
                sut.loadViewIfNeeded()

                expect(sut.navigationItem.largeTitleDisplayMode).to(equal(.never))
            }
        }

        describe("view actions") {
            beforeEach {
                sut.loadViewIfNeeded()
            }

            it("forwards the retry") {
                contentView.onRetry?()

                expect(presenter.retryCount).to(equal(1))
            }

            it("forwards the video tap") {
                contentView.onVideoTap?()

                expect(presenter.videoTapCount).to(equal(1))
            }

            it("forwards the ingredients of the shopping cart") {
                contentView.onShoppingCartTap?(["Rice"])

                expect(presenter.shoppingCartIngredients).to(equal([["Rice"]]))
            }

            it("does not retain the view controller in the actions") {
                weak let weakSUT = sut

                sut = nil

                expect(weakSUT).to(beNil())
            }
        }

        describe("DetailViewControllerType") {
            it("displays the title") {
                sut.display(title: "Soup")

                expect(sut.title).to(equal("Soup"))
            }

            it("forwards the state to the content view") {
                sut.render(.loading)

                expect(contentView.renderedStates).to(equal([.loading]))
            }
        }
    }
}
