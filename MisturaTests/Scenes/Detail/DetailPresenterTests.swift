import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class DetailPresenterTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var mealRepository: MealRepositoryStub!
        nonisolated(unsafe) var historyRepository: HistoryRepositoryStub!
        nonisolated(unsafe) var viewController: DetailViewControllerSpy!
        nonisolated(unsafe) var coordinator: DetailCoordinatorSpy!
        nonisolated(unsafe) var sut: DetailPresenter!

        beforeEach { @MainActor in
            mealRepository = MealRepositoryStub()
            historyRepository = HistoryRepositoryStub()
            viewController = DetailViewControllerSpy()
            coordinator = DetailCoordinatorSpy()
            sut = DetailPresenter(
                meal: MealSummary(id: "1", name: "Soup", thumbnailURL: nil),
                mealRepository: mealRepository,
                historyRepository: historyRepository
            )
            sut.viewController = viewController
            sut.coordinator = coordinator
        }

        describe("viewDidLoad") {
            it("displays the meal name") { @MainActor in
                sut.viewDidLoad()

                expect(viewController.displayedTitles).to(equal(["Soup"]))
            }

            it("renders loading before the response arrives") { @MainActor in
                sut.viewDidLoad()

                expect(viewController.renderedStates).to(equal([.loading]))
            }

            context("when the meal is found") {
                it("renders the loaded state") { @MainActor in
                    mealRepository.detailResult = .success(makeDetail())

                    sut.viewDidLoad()

                    await expect { @MainActor in viewController.renderedStates.count }.toEventually(equal(2))
                    expect(viewController.loadedModel).toNot(beNil())
                }

                it("saves the meal to the history") { @MainActor in
                    let detail = makeDetail()
                    mealRepository.detailResult = .success(detail)

                    sut.viewDidLoad()

                    await expect { @MainActor in historyRepository.savedMeals }.toEventually(equal([detail.summary]))
                }

                it("still renders the meal when saving to the history fails") { @MainActor in
                    mealRepository.detailResult = .success(makeDetail())
                    historyRepository.saveError = TestError.any

                    sut.viewDidLoad()

                    await expect { @MainActor in viewController.loadedModel }.toEventuallyNot(beNil())
                    expect(historyRepository.savedMeals).to(beEmpty())
                }
            }

            context("when the meal does not exist") {
                it("renders the not found error") { @MainActor in
                    mealRepository.detailResult = .success(nil)

                    sut.viewDidLoad()

                    await expect { @MainActor in viewController.renderedStates.last }
                        .toEventually(equal(.error(TextStrings.detailNotFound)))
                    expect(historyRepository.savedMeals).to(beEmpty())
                }
            }

            context("when the request fails") {
                it("renders the load error") { @MainActor in
                    mealRepository.detailResult = .failure(TestError.any)

                    sut.viewDidLoad()

                    await expect { @MainActor in viewController.renderedStates.last }
                        .toEventually(equal(.error(TextStrings.detailLoadError)))
                }
            }
        }

        describe("didTapRetry") {
            it("loads the meal again and renders it") { @MainActor in
                mealRepository.detailResult = .failure(TestError.any)
                sut.viewDidLoad()
                await expect { @MainActor in viewController.renderedStates.last }
                    .toEventually(equal(.error(TextStrings.detailLoadError)))
                mealRepository.detailResult = .success(makeDetail())

                sut.didTapRetry()

                expect(viewController.renderedStates.last).to(equal(.loading))
                await expect { @MainActor in viewController.loadedModel }.toEventuallyNot(beNil())
            }

            it("cancels the previous request") { @MainActor in
                let gate = AsyncGate()
                gate.isHeld = true
                mealRepository.detailGate = gate
                sut.viewDidLoad()
                await expect { @MainActor in gate.waitCount }.toEventually(equal(1))

                sut.didTapRetry()

                await expect { @MainActor in gate.cancelledCount }.toEventually(equal(1))
            }
        }

        describe("didTapVideo") {
            it("opens the video of the loaded meal") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(youtubeURL: videoURL))
                sut.viewDidLoad()
                await expect { @MainActor in viewController.loadedModel }.toEventuallyNot(beNil())

                sut.didTapVideo()

                expect(coordinator.openedLinks).to(equal([videoURL]))
            }

            it("does nothing when the meal has no video") { @MainActor in
                mealRepository.detailResult = .success(makeDetail())
                sut.viewDidLoad()
                await expect { @MainActor in viewController.loadedModel }.toEventuallyNot(beNil())

                sut.didTapVideo()

                expect(coordinator.openedLinks).to(beEmpty())
            }

            it("does nothing before the meal is loaded") { @MainActor in
                sut.didTapVideo()

                expect(coordinator.openedLinks).to(beEmpty())
            }
        }

        describe("didTapShoppingCart") {
            it("opens iFood Mercado with one numbered item per ingredient") { @MainActor in
                sut.didTapShoppingCart(ingredients: ["Rice", "Salt"])

                let link = coordinator.openedLinks.first
                expect(link?.host).to(equal("www.ifood.com.br"))
                expect(link?.path).to(equal("/mercado"))
                expect(queryItems(of: link)).to(equal([
                    URLQueryItem(name: "item1", value: "Rice"),
                    URLQueryItem(name: "item2", value: "Salt")
                ]))
            }

            it("encodes the ingredient text") { @MainActor in
                sut.didTapShoppingCart(ingredients: ["1 lb Ground Beef"])

                expect(coordinator.openedLinks.first?.absoluteString).to(contain("item1=1%20lb%20Ground%20Beef"))
            }

            it("opens the page without items when no ingredient is left") { @MainActor in
                sut.didTapShoppingCart(ingredients: [])

                expect(coordinator.openedLinks).to(haveCount(1))
                expect(queryItems(of: coordinator.openedLinks.first)).to(beEmpty())
            }
        }

        describe("subtitle") {
            it("joins the category and the area") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(category: "Starter", area: "French"))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.subtitle }
                    .toEventually(equal("Starter · French"))
            }

            it("ignores an empty area") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(category: "Starter", area: ""))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.subtitle }.toEventually(equal("Starter"))
            }

            it("ignores a missing category") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(category: nil, area: "French"))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.subtitle }.toEventually(equal("French"))
            }

            it("is nil when there is neither category nor area") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(category: "", area: nil))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel }.toEventuallyNot(beNil())
                expect(viewController.loadedModel?.subtitle).to(beNil())
            }
        }

        describe("image") {
            it("uses the full size image instead of the thumbnail") { @MainActor in
                let imageURL = URL(string: "https://example.com/soup.jpg")
                let thumbnailURL = URL(string: "https://example.com/soup.jpg/small")
                mealRepository.detailResult = .success(makeDetail(imageURL: imageURL, thumbnailURL: thumbnailURL))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.imageURL }.toEventually(equal(imageURL))
            }
        }

        describe("tags") {
            it("prefixes and joins the tags") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(tags: ["Meat", "Casserole"]))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.tags }.toEventually(equal("#Meat #Casserole"))
            }

            it("is nil when there are no tags") { @MainActor in
                mealRepository.detailResult = .success(makeDetail())

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel }.toEventuallyNot(beNil())
                expect(viewController.loadedModel?.tags).to(beNil())
            }
        }

        describe("ingredients") {
            it("joins the measure and the name") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(ingredients: [
                    Ingredient(name: "Rice", measure: "2 cups")
                ]))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.ingredients }
                    .toEventually(equal(["2 cups Rice"]))
            }

            it("uses only the name when the measure is empty") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(ingredients: [
                    Ingredient(name: "Salt", measure: "  ")
                ]))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.ingredients }.toEventually(equal(["Salt"]))
            }
        }

        describe("instructions") {
            it("removes blank lines and separates the paragraphs") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(instructions: "  Boil.\r\n\r\n   \nServe. "))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.instructions }
                    .toEventually(equal("Boil.\n\nServe."))
            }
        }

        describe("hasVideo") {
            it("is true when the meal has a video") { @MainActor in
                mealRepository.detailResult = .success(makeDetail(youtubeURL: videoURL))

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.hasVideo }.toEventually(beTrue())
            }

            it("is false when the meal has no video") { @MainActor in
                mealRepository.detailResult = .success(makeDetail())

                sut.viewDidLoad()

                await expect { @MainActor in viewController.loadedModel?.hasVideo }.toEventually(beFalse())
            }
        }

        describe("deinit") {
            it("cancels the ongoing request") { @MainActor in
                let gate = AsyncGate()
                gate.isHeld = true
                mealRepository.detailGate = gate
                sut.viewDidLoad()
                await expect { @MainActor in gate.waitCount }.toEventually(equal(1))

                sut = nil

                await expect { @MainActor in gate.cancelledCount }.toEventually(equal(1))
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
        }
    }
}

private let videoURL = URL(string: "https://www.youtube.com/watch?v=abc")!

private func queryItems(of url: URL?) -> [URLQueryItem] {
    url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
}

private func makeDetail(
    category: String? = nil,
    area: String? = nil,
    instructions: String = "",
    imageURL: URL? = nil,
    thumbnailURL: URL? = nil,
    youtubeURL: URL? = nil,
    tags: [String] = [],
    ingredients: [Ingredient] = []
) -> MealDetail {
    MealDetail(
        id: "1",
        name: "Soup",
        category: category,
        area: area,
        instructions: instructions,
        imageURL: imageURL,
        thumbnailURL: thumbnailURL,
        youtubeURL: youtubeURL,
        tags: tags,
        ingredients: ingredients
    )
}
