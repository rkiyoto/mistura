import UIKit

extension UIImageView {
    @discardableResult
    func loadImage(from url: URL?, loader: ImageLoaderType = ImageLoader.shared) -> Task<Void, Never>? {
        image = nil
        guard let url else { return nil }
        return Task { [weak self] in
            let image = await loader.image(for: url)
            guard !Task.isCancelled else { return }
            self?.image = image
        }
    }
}
