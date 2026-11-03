import UIKit
@testable import Mistura

final class SearchViewControllerSpy: SearchViewControllerType {
    private(set) var renderedStates: [SearchViewState] = []

    func render(_ state: SearchViewState) {
        renderedStates.append(state)
    }
}
