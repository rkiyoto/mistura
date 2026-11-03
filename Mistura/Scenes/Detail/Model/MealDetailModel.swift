import Foundation

struct MealDetailModel: Equatable {
    let imageURL: URL?
    let subtitle: String?
    let tags: String?
    let ingredients: [String]
    let instructions: String
    let hasVideo: Bool
}
