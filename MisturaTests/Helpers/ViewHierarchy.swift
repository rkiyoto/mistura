import UIKit

extension UIView {
    var viewsInHierarchy: [UIView] {
        [self] + subviews.flatMap(\.viewsInHierarchy)
    }

    func firstView<View: UIView>(of type: View.Type, where predicate: (View) -> Bool = { _ in true }) -> View? {
        viewsInHierarchy.lazy.compactMap { $0 as? View }.first(where: predicate)
    }

    func button(titled title: String) -> UIButton? {
        firstView(of: UIButton.self) { $0.configuration?.title == title }
    }

    func button(accessibilityLabel label: String) -> UIButton? {
        firstView(of: UIButton.self) { $0.accessibilityLabel == label }
    }

    func label(showing text: String) -> UILabel? {
        firstView(of: UILabel.self) { $0.text == text }
    }

    func imageView(showing image: UIImage) -> UIImageView? {
        firstView(of: UIImageView.self) { $0.image === image }
    }
}

extension UIButton {
    func simulateTap() {
        sendActions(for: .touchUpInside)
    }
}
