import Nimble
import Quick
import UIKit
@testable import Mistura

nonisolated final class ImageLoaderTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var client: HTTPClientStub!
        nonisolated(unsafe) var sut: ImageLoader!

        let imageURL = URL(string: "https://example.com/soup.jpg")!
        let otherImageURL = URL(string: "https://example.com/rice.jpg")!

        beforeEach { @MainActor in
            client = HTTPClientStub()
            client.result = .success(makeImageData())
            sut = ImageLoader(client: client)
        }

        describe("image(for:)") {
            it("requests the given URL") { @MainActor in
                _ = await sut.image(for: imageURL)

                expect(client.requestedURLs).to(equal([imageURL]))
            }

            it("returns the downloaded image") { @MainActor in
                let image = await sut.image(for: imageURL)

                expect(image).toNot(beNil())
            }

            it("returns nil when the request fails") { @MainActor in
                client.result = .failure(TestError.any)

                let image = await sut.image(for: imageURL)

                expect(image).to(beNil())
            }

            it("returns nil when the data is not an image") { @MainActor in
                client.result = .success(Data("not an image".utf8))

                let image = await sut.image(for: imageURL)

                expect(image).to(beNil())
            }
        }

        describe("cache") {
            it("does not request the same image twice") { @MainActor in
                let first = await sut.image(for: imageURL)

                let second = await sut.image(for: imageURL)

                expect(second).to(beIdenticalTo(first))
                expect(client.requestedURLs).to(haveCount(1))
            }

            it("requests each URL separately") { @MainActor in
                _ = await sut.image(for: imageURL)

                _ = await sut.image(for: otherImageURL)

                expect(client.requestedURLs).to(equal([imageURL, otherImageURL]))
            }

            it("does not cache a failure") { @MainActor in
                client.result = .failure(TestError.any)
                _ = await sut.image(for: imageURL)
                client.result = .success(makeImageData())

                let image = await sut.image(for: imageURL)

                expect(image).toNot(beNil())
                expect(client.requestedURLs).to(haveCount(2))
            }
        }
    }
}

private func makeImageData() -> Data {
    makeImage().pngData() ?? Data()
}
