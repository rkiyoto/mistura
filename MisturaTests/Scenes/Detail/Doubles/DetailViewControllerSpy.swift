import UIKit
@testable import Mistura

final class DetailViewControllerSpy: DetailViewControllerType {
    private(set) var renderedStates: [DetailViewState] = []
    private(set) var displayedTitles: [String] = []

    var loadedModel: MealDetailModel? {
        guard case .loaded(let model) = renderedStates.last else { return nil }
        return model
    }

    func display(title: String) {
        displayedTitles.append(title)
    }

    func render(_ state: DetailViewState) {
        renderedStates.append(state)
    }
}
