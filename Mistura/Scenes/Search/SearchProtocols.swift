import UIKit

protocol SearchViewControllerType: AnyObject {
    func render(_ state: SearchViewState)
}

protocol SearchPresenterType {
    func viewDidLoad()
    func viewWillAppear()
    func searchDidBeginEditing()
    func searchTextDidChange(_ text: String)
    func searchTypeDidChange(_ type: SearchType)
    func searchDidCancel()
    func didSelectItem(at index: Int)
    func didTapRetry()
    func didTapClearHistory()
}

protocol SearchCoordinatorDelegate: AnyObject {
    func showDetail(for meal: MealSummary)
}

protocol SearchViewType where Self: UIView {
    var onSelectItem: ((Int) -> Void)? { get set }
    var onRetry: (() -> Void)? { get set }
    var onClearHistory: (() -> Void)? { get set }

    func render(_ state: SearchViewState)
}
