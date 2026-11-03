import UIKit

protocol ImageLoaderType {
    func image(for url: URL) async -> UIImage?
}

final class ImageLoader: ImageLoaderType {
    static let shared = ImageLoader()

    private let client: HTTPClient
    private let cache = NSCache<NSURL, UIImage>()

    init(client: HTTPClient = URLSessionHTTPClient()) {
        self.client = client
    }

    func image(for url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        guard let data = try? await client.makeRequest(from: url),
              let image = UIImage(data: data) else {
            return nil
        }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
