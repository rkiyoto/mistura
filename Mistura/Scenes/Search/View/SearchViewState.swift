enum SearchViewState: Equatable {
    case idle
    case history([MealCellModel])
    case loading
    case results([MealCellModel])
    case empty(String)
    case error(String)
}
