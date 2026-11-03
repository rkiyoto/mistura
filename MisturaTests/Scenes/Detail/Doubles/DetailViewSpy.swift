import UIKit
@testable import Mistura

final class DetailViewSpy: UIView, DetailViewType {
    var onRetry: (() -> Void)?
    var onVideoTap: (() -> Void)?
    var onShoppingCartTap: (([String]) -> Void)?

    private(set) var renderedStates: [DetailViewState] = []

    func render(_ state: DetailViewState) {
        renderedStates.append(state)
    }
}
