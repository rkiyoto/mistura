enum DetailViewState: Equatable {
    case loading
    case loaded(MealDetailModel)
    case error(String)
}
