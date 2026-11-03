import UIKit
@testable import Mistura

final class ImageLoaderStub: ImageLoaderType {
    var image: UIImage?
    var gate: AsyncGate?

    private(set) var requestedURLs: [URL] = []

    func image(for url: URL) async -> UIImage? {
        requestedURLs.append(url)
        try? await gate?.wait()
        return image
    }
}
