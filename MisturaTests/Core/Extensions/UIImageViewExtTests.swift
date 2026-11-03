import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class UIImageViewExtTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var loader: ImageLoaderStub!
        nonisolated(unsafe) var sut: UIImageView!

        let imageURL = URL(string: "https://example.com/soup.jpg")!

        beforeEach { @MainActor in
            loader = ImageLoaderStub()
            sut = UIImageView()
        }

        describe("loadImage") {
            context("when the URL is nil") {
                it("clears the image without calling the loader") { @MainActor in
                    sut.image = makeImage()

                    let task = sut.loadImage(from: nil, loader: loader)

                    expect(task).to(beNil())
                    expect(sut.image).to(beNil())
                    expect(loader.requestedURLs).to(beEmpty())
                }
            }

            context("when there is a URL") {
                it("shows the loaded image") { @MainActor in
                    let image = makeImage()
                    loader.image = image

                    await sut.loadImage(from: imageURL, loader: loader)?.value

                    expect(sut.image).to(beIdenticalTo(image))
                    expect(loader.requestedURLs).to(equal([imageURL]))
                }

                it("clears the previous image while loading") { @MainActor in
                    let gate = AsyncGate()
                    gate.isHeld = true
                    loader.gate = gate
                    sut.image = makeImage()

                    let task = sut.loadImage(from: imageURL, loader: loader)

                    expect(sut.image).to(beNil())
                    gate.release()
                    await task?.value
                }
            }

            context("when the task is cancelled") {
                it("does not show the image") { @MainActor in
                    let gate = AsyncGate()
                    gate.isHeld = true
                    loader.gate = gate
                    loader.image = makeImage()
                    let task = sut.loadImage(from: imageURL, loader: loader)
                    await expect { @MainActor in gate.waitCount }.toEventually(equal(1))

                    task?.cancel()
                    await task?.value

                    expect(gate.cancelledCount).to(equal(1))
                    expect(sut.image).to(beNil())
                }
            }
        }
    }
}
