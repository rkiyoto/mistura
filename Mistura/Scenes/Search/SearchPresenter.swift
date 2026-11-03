import Foundation
import os

final class SearchPresenter {
    weak var viewController: SearchViewControllerType?
    weak var coordinator: SearchCoordinatorDelegate?

    private let mealRepository: MealRepositoryType
    private let historyRepository: HistoryRepositoryType
    private let waitForDebounce: () async throws -> Void
    private let logger = Logger(subsystem: "Mistura", category: "Search")

    private var query = ""
    private var searchType: SearchType = .name
    private var isEditing = false
    
    private var displayedMeals: [MealSummary] = []
    private var searchTask: Task<Void, Never>?

    init(
        mealRepository: MealRepositoryType,
        historyRepository: HistoryRepositoryType,
        waitForDebounce: @escaping () async throws -> Void = { try await Task.sleep(nanoseconds: 400_000_000) }
    ) {
        self.mealRepository = mealRepository
        self.historyRepository = historyRepository
        self.waitForDebounce = waitForDebounce
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Private

    private func showHistory() {
        let history = (try? historyRepository.recentMeals()) ?? []
        displayedMeals = history
        
        if history.isEmpty {
            viewController?.render(.idle)
            return
        }
        
        let models = history.map { MealCellModel(meal: $0) }
        viewController?.render(.history(models))
    }

    private func scheduleSearch(debounced: Bool) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            isEditing ? showHistory() : showIdle()
            return
        }

        searchTask = Task { [weak self, mealRepository, waitForDebounce, query, searchType] in
            if debounced {
                do { try await waitForDebounce() } catch { return }
            }
            guard !Task.isCancelled else { return }
            self?.showLoading()

            do {
                let meals = try await mealRepository.searchMeals(query: query, type: searchType)
                guard !Task.isCancelled else { return }

                self?.handleSearchSuccess(meals: meals)
            } catch {
                guard !Task.isCancelled else { return }

                self?.handleSearchFailure()
            }
        }
    }

    private func showLoading() {
        displayedMeals = []
        viewController?.render(.loading)
    }

    private func handleSearchSuccess(meals: [MealSummary]) {
        let meals = meals.filter { !$0.name.isEmpty }
        displayedMeals = meals

        if meals.isEmpty {
            viewController?.render(.empty(TextStrings.searchEmptyMessage(query: query)))
            return
        }
        
        let models = meals.map { MealCellModel(meal: $0) }
        viewController?.render(.results(models))
    }
    
    private func handleSearchFailure() {
        viewController?.render(.error(TextStrings.searchErrorMessage))
    }

    private func showIdle() {
        displayedMeals = []
        viewController?.render(.idle)
    }
}

// MARK: - SearchPresenterType

extension SearchPresenter: SearchPresenterType {
    func viewDidLoad() {
        showIdle()
    }
    
    func viewWillAppear() {
        if isEditing && query.isEmpty {
            showHistory()
        }
    }

    func searchDidBeginEditing() {
        isEditing = true
        if query.isEmpty {
            showHistory()
        }
    }

    func searchTextDidChange(_ text: String) {
        query = text.trimmingCharacters(in: .whitespaces)
        scheduleSearch(debounced: true)
    }

    func searchTypeDidChange(_ type: SearchType) {
        searchType = type
        scheduleSearch(debounced: false)
    }

    func searchDidCancel() {
        searchTask?.cancel()
        query = ""
        isEditing = false
        showIdle()
    }

    func didSelectItem(at index: Int) {
        guard displayedMeals.indices.contains(index) else { return }
        coordinator?.showDetail(for: displayedMeals[index])
    }
    
    func didTapRetry() {
        scheduleSearch(debounced: false)
    }
    
    func didTapClearHistory() {
        do {
            try historyRepository.clearHistory()
            displayedMeals = []
            showIdle()
        } catch {
            logger.error("\(TextStrings.searchClearError) \(error.localizedDescription)")
        }
    }
}
