import Foundation
import os

final class DetailPresenter {
    weak var viewController: DetailViewControllerType?
    weak var coordinator: DetailCoordinatorDelegate?

    private let meal: MealSummary
    private let mealRepository: MealRepositoryType
    private let historyRepository: HistoryRepositoryType
    private let logger = Logger(subsystem: "Mistura", category: "Detail")

    private var detail: MealDetail?
    private var loadTask: Task<Void, Never>?

    init(meal: MealSummary,
         mealRepository: MealRepositoryType,
         historyRepository: HistoryRepositoryType) {
        self.meal = meal
        self.mealRepository = mealRepository
        self.historyRepository = historyRepository
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Private

    private func loadDetail() {
        loadTask?.cancel()
        viewController?.render(.loading)

        loadTask = Task { [weak self, meal, mealRepository] in
            do {
                let detail = try await mealRepository.mealDetail(id: meal.id)
                guard !Task.isCancelled else { return }
                self?.handle(detail)
            } catch {
                guard !Task.isCancelled else { return }
                self?.viewController?.render(.error(TextStrings.detailLoadError))
            }
        }
    }

    private func handle(_ detail: MealDetail?) {
        guard let detail else {
            viewController?.render(.error(TextStrings.detailNotFound))
            return
        }
        self.detail = detail
        saveToHistory(detail.summary)
        viewController?.render(.loaded(makeModel(from: detail)))
    }

    private func saveToHistory(_ meal: MealSummary) {
        do {
            try historyRepository.save(meal)
        } catch {
            logger.error("\(TextStrings.historySaveError) \(error.localizedDescription)")
        }
    }

    private func makeModel(from detail: MealDetail) -> MealDetailModel {
        let subtitle = [detail.category, detail.area]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        let ingredients = detail.ingredients.map { ingredient in
            return [ingredient.measure, ingredient.name]
                .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        let instructions = detail.instructions
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        return MealDetailModel(
            imageURL: detail.imageURL,
            subtitle: subtitle.isEmpty ? nil : subtitle,
            tags: detail.tags.isEmpty ? nil : detail.tags.map { "#\($0)" }.joined(separator: " "),
            ingredients: ingredients,
            instructions: instructions,
            hasVideo: detail.youtubeURL != nil
        )
    }
}

// MARK: - DetailPresenterType

extension DetailPresenter: DetailPresenterType {
    func viewDidLoad() {
        viewController?.display(title: meal.name)
        loadDetail()
    }

    func didTapRetry() {
        loadDetail()
    }

    func didTapVideo() {
        guard let url = detail?.youtubeURL else { return }
        coordinator?.openExternalLink(url)
    }

    func didTapShoppingCart(ingredients: [String]) {
        var components = URLComponents(string: "https://www.ifood.com.br/mercado")

        let ingredientParams = ingredients.enumerated().map { index, ingredient in
            URLQueryItem(name: "item\(index + 1)", value: ingredient)
        }

        components?.queryItems = ingredientParams

        guard let url = components?.url else { return }
        coordinator?.openExternalLink(url)
    }
}
