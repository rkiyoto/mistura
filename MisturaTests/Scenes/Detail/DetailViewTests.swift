import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class DetailViewTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var loader: ImageLoaderStub!
        nonisolated(unsafe) var sut: DetailView!

        beforeEach { @MainActor in
            loader = ImageLoaderStub()
            sut = DetailView(imageLoader: loader)
        }

        describe("render") {
            it("shows only the activity indicator while loading") { @MainActor in
                sut.render(.loading)

                assertRenderSnapshot(of: sut, named: "loading")
            }

            it("shows every section of a complete meal") { @MainActor in
                sut.render(.loaded(makeModel()))

                assertRenderSnapshot(of: sut, named: "loaded")
            }

            it("hides the optional sections of a minimal meal") { @MainActor in
                sut.render(.loaded(makeModel(subtitle: nil, tags: nil, hasVideo: false)))

                assertRenderSnapshot(of: sut, named: "loaded-minimal")
            }

            it("shows the error message with the retry button") { @MainActor in
                sut.render(.error(TextStrings.detailLoadError))

                assertRenderSnapshot(of: sut, named: "error")
            }

            it("removes the error when moving from error to loaded") { @MainActor in
                sut.render(.error(TextStrings.detailLoadError))

                sut.render(.loaded(makeModel()))

                assertRenderSnapshot(of: sut, named: "error-to-loaded")
            }

            it("removes the content when moving from loaded to error") { @MainActor in
                sut.render(.loaded(makeModel()))

                sut.render(.error(TextStrings.detailLoadError))

                assertRenderSnapshot(of: sut, named: "loaded-to-error")
            }
        }

        describe("image") {
            it("shows the image of the injected loader") { @MainActor in
                let image = makeImage()
                loader.image = image

                sut.render(.loaded(makeModel(imageURL: imageURL)))

                await expect { @MainActor in sut.imageView(showing: image) }.toEventuallyNot(beNil())
                expect(loader.requestedURLs).to(equal([imageURL]))
            }

            it("does not call the loader without a URL") { @MainActor in
                sut.render(.loaded(makeModel(imageURL: nil)))

                await Task.yield()

                expect(loader.requestedURLs).to(beEmpty())
            }
        }

        describe("ingredients") {
            it("ignores empty ingredients") { @MainActor in
                sut.render(.loaded(makeModel(ingredients: ["Rice", "", "Salt"])))

                expect(ingredientRows(in: sut).map(\.ingredient)).to(equal(["Rice", "Salt"]))
            }

            it("replaces the rows of the previous meal") { @MainActor in
                sut.render(.loaded(makeModel(ingredients: ["Rice", "Salt"])))

                sut.render(.loaded(makeModel(ingredients: ["Bread"])))

                expect(ingredientRows(in: sut).map(\.ingredient)).to(equal(["Bread"]))
            }
        }

        describe("actions") {
            it("calls onRetry when the retry button is tapped") { @MainActor in
                var retryCount = 0
                sut.onRetry = { retryCount += 1 }
                sut.render(.error(TextStrings.detailLoadError))

                sut.button(titled: TextStrings.retryButton)?.simulateTap()

                expect(retryCount).to(equal(1))
            }

            it("calls onVideoTap when the video button is tapped") { @MainActor in
                var videoTapCount = 0
                sut.onVideoTap = { videoTapCount += 1 }
                sut.render(.loaded(makeModel()))

                sut.button(accessibilityLabel: TextStrings.watchVideoAccessibilityLabel)?.simulateTap()

                expect(videoTapCount).to(equal(1))
            }

            it("hides the video button when there is no video") { @MainActor in
                sut.render(.loaded(makeModel(hasVideo: false)))

                expect(sut.button(accessibilityLabel: TextStrings.watchVideoAccessibilityLabel)?.isHidden)
                    .to(beTrue())
            }

            it("sends every ingredient to the cart when none is checked") { @MainActor in
                var received: [[String]] = []
                sut.onShoppingCartTap = { received.append($0) }
                sut.render(.loaded(makeModel(ingredients: ["Rice", "Salt"])))

                sut.button(titled: TextStrings.shoppingCartButton)?.simulateTap()

                expect(received).to(equal([["Rice", "Salt"]]))
            }

            it("does not send the checked ingredients to the cart") { @MainActor in
                var received: [[String]] = []
                sut.onShoppingCartTap = { received.append($0) }
                sut.render(.loaded(makeModel(ingredients: ["Rice", "Salt"])))
                ingredientRows(in: sut).first?.firstView(of: UIButton.self)?.simulateTap()

                sut.button(titled: TextStrings.shoppingCartButton)?.simulateTap()

                expect(received).to(equal([["Salt"]]))
            }

            it("sends an empty list when every ingredient is checked") { @MainActor in
                var received: [[String]] = []
                sut.onShoppingCartTap = { received.append($0) }
                sut.render(.loaded(makeModel(ingredients: ["Rice"])))
                ingredientRows(in: sut).first?.firstView(of: UIButton.self)?.simulateTap()

                sut.button(titled: TextStrings.shoppingCartButton)?.simulateTap()

                expect(received).to(equal([[]]))
            }
        }
    }
}

private let imageURL = URL(string: "https://example.com/soup.jpg")!

private func ingredientRows(in view: UIView) -> [IngredientItemView] {
    view.viewsInHierarchy.compactMap { $0 as? IngredientItemView }
}

// Sem URL de imagem por padrão, para que o resultado não dependa do carregamento
private func makeModel(
    imageURL: URL? = nil,
    subtitle: String? = "Starter · Tunisian",
    tags: String? = "#Soup #Vegetarian",
    ingredients: [String] = ["2 cups Chickpeas", "1 tbsp Harissa", "Salt"],
    hasVideo: Bool = true
) -> MealDetailModel {
    MealDetailModel(
        imageURL: imageURL,
        subtitle: subtitle,
        tags: tags,
        ingredients: ingredients,
        instructions: "Boil the chickpeas.\n\nServe with harissa.",
        hasVideo: hasVideo
    )
}
