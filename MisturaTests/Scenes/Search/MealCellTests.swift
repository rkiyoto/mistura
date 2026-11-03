import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class MealCellTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var loader: ImageLoaderStub!
        nonisolated(unsafe) var sut: MealCell!

        let imageURL = URL(string: "https://example.com/soup.jpg/small")!
        let cellSize = CGSize(width: 402, height: 72)

        beforeEach { @MainActor in
            loader = ImageLoaderStub()
            sut = MealCell(style: .default, reuseIdentifier: MealCell.reuseIdentifier)
        }

        describe("MealCellModel") {
            it("is built from the meal summary") { @MainActor in
                let meal = MealSummary(id: "1", name: "Soup", thumbnailURL: imageURL)

                expect(MealCellModel(meal: meal)).to(equal(MealCellModel(id: "1", title: "Soup", imageURL: imageURL)))
            }
        }

        describe("configure") {
            it("shows the title") { @MainActor in
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: nil), imageLoader: loader)

                expect(sut.label(showing: "Soup")).toNot(beNil())
            }

            it("does not call the loader without a URL") { @MainActor in
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: nil), imageLoader: loader)

                await Task.yield()

                expect(loader.requestedURLs).to(beEmpty())
            }

            it("shows the loaded image") { @MainActor in
                let image = makeImage()
                loader.image = image

                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: imageURL), imageLoader: loader)

                await expect { @MainActor in sut.imageView(showing: image) }.toEventuallyNot(beNil())
                expect(loader.requestedURLs).to(equal([imageURL]))
            }

            it("cancels the previous load when configured again") { @MainActor in
                let gate = AsyncGate()
                gate.isHeld = true
                loader.gate = gate
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: imageURL), imageLoader: loader)
                await expect { @MainActor in gate.waitCount }.toEventually(equal(1))

                sut.configure(with: MealCellModel(id: "2", title: "Rice", imageURL: nil), imageLoader: loader)

                await expect { @MainActor in gate.cancelledCount }.toEventually(equal(1))
            }
        }

        describe("prepareForReuse") {
            it("clears the image") { @MainActor in
                let image = makeImage()
                loader.image = image
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: imageURL), imageLoader: loader)
                await expect { @MainActor in sut.imageView(showing: image) }.toEventuallyNot(beNil())

                sut.prepareForReuse()

                expect(sut.imageView(showing: image)).to(beNil())
            }

            it("cancels the ongoing load") { @MainActor in
                let gate = AsyncGate()
                gate.isHeld = true
                loader.gate = gate
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: imageURL), imageLoader: loader)
                await expect { @MainActor in gate.waitCount }.toEventually(equal(1))

                sut.prepareForReuse()

                await expect { @MainActor in gate.cancelledCount }.toEventually(equal(1))
            }
        }

        describe("layout") {
            it("shows the placeholder and the title") { @MainActor in
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: nil), imageLoader: loader)

                assertRenderSnapshot(of: sut, named: "placeholder", size: cellSize)
            }

            it("limits a long title to two lines") { @MainActor in
                let title = String(repeating: "Beef Banh Mi Bowls with Sriracha Mayo ", count: 5)
                sut.configure(with: MealCellModel(id: "1", title: title, imageURL: nil), imageLoader: loader)

                assertRenderSnapshot(of: sut, named: "long-title", size: cellSize)
            }

            it("shows the loaded image") { @MainActor in
                let image = makeImage()
                loader.image = image
                sut.configure(with: MealCellModel(id: "1", title: "Soup", imageURL: imageURL), imageLoader: loader)
                await expect { @MainActor in sut.imageView(showing: image) }.toEventuallyNot(beNil())

                assertRenderSnapshot(of: sut, named: "image", size: cellSize)
            }
        }
    }
}
