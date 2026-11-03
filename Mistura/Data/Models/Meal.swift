import Foundation

struct MealSummary: Equatable {
    let id: String
    let name: String
    let thumbnailURL: URL?
}

struct MealDetail: Equatable {
    let id: String
    let name: String
    let category: String?
    let area: String?
    let instructions: String
    let imageURL: URL?
    let thumbnailURL: URL?
    let youtubeURL: URL?
    let tags: [String]
    let ingredients: [Ingredient]

    var summary: MealSummary {
        MealSummary(id: id,
                    name: name,
                    thumbnailURL: thumbnailURL)
    }
}

struct Ingredient: Equatable {
    let name: String
    let measure: String
}

enum SearchType: CaseIterable {
    case name
    case ingredient

    var title: String {
        switch self {
        case .name: TextStrings.searchTypeName
        case .ingredient: TextStrings.searchTypeIngredient
        }
    }
}
