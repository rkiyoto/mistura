import UIKit
@testable import Mistura

final class SearchViewSpy: UIView, SearchViewType {
    var onSelectItem: ((Int) -> Void)?
    var onRetry: (() -> Void)?
    var onClearHistory: (() -> Void)?

    private(set) var renderedStates: [SearchViewState] = []

    func render(_ state: SearchViewState) {
        renderedStates.append(state)
    }
}
