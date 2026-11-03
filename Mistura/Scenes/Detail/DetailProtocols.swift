import Foundation
import UIKit

protocol DetailCoordinatorDelegate: AnyObject {
    func openExternalLink(_ url: URL)
}

protocol DetailPresenterType: AnyObject {
    func viewDidLoad()
    func didTapRetry()
    func didTapVideo()
    func didTapShoppingCart(ingredients: [String])
}

protocol DetailViewControllerType: AnyObject {
    func display(title: String)
    func render(_ state: DetailViewState)
}

protocol DetailViewType where Self: UIView {
    var onRetry: (() -> Void)? { get set }
    var onVideoTap: (() -> Void)? { get set }
    var onShoppingCartTap: (([String]) -> Void)? { get set }

    func render(_ state: DetailViewState)
}
