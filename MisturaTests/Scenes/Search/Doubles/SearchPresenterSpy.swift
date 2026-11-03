import Foundation
@testable import Mistura

final class SearchPresenterSpy: SearchPresenterType {
    private(set) var viewDidLoadCount = 0
    private(set) var viewWillAppearCount = 0
    private(set) var beginEditingCount = 0
    private(set) var cancelCount = 0
    private(set) var retryCount = 0
    private(set) var clearHistoryCount = 0
    private(set) var searchTexts: [String] = []
    private(set) var searchTypes: [SearchType] = []
    private(set) var selectedIndexes: [Int] = []

    func viewDidLoad() {
        viewDidLoadCount += 1
    }

    func viewWillAppear() {
        viewWillAppearCount += 1
    }

    func searchDidBeginEditing() {
        beginEditingCount += 1
    }

    func searchTextDidChange(_ text: String) {
        searchTexts.append(text)
    }

    func searchTypeDidChange(_ type: SearchType) {
        searchTypes.append(type)
    }

    func searchDidCancel() {
        cancelCount += 1
    }

    func didSelectItem(at index: Int) {
        selectedIndexes.append(index)
    }

    func didTapRetry() {
        retryCount += 1
    }

    func didTapClearHistory() {
        clearHistoryCount += 1
    }
}
