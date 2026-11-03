import Foundation

struct MealDTO: Decodable {
    struct IngredientDTO {
        let name: String
        let measure: String?
    }

    let idMeal: String
    let strMeal: String
    let strMealThumb: String?
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strYoutube: String?
    let strTags: String?
    let ingredients: [IngredientDTO]

    private static let maxIngredients = 20

    private struct DynamicKey: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }

        init(_ stringValue: String) { self.stringValue = stringValue }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)

        func optionalString(_ key: String) -> String? {
            (try? container.decodeIfPresent(String.self, forKey: DynamicKey(key)))?.trimmingCharacters(in: .whitespaces)
        }

        idMeal = try container.decode(String.self, forKey: DynamicKey("idMeal"))
        strMeal = optionalString("strMeal") ?? ""
        strMealThumb = optionalString("strMealThumb")
        strCategory = optionalString("strCategory")
        strArea = optionalString("strArea")
        strInstructions = optionalString("strInstructions")
        strYoutube = optionalString("strYoutube")
        strTags = optionalString("strTags")
        ingredients = (1...Self.maxIngredients).compactMap { index in
            guard let name = optionalString("strIngredient\(index)") else { return nil }
            return IngredientDTO(name: name, measure: optionalString("strMeasure\(index)"))
        }
    }
}

// MARK: - Domain Mapping

extension MealDTO {
    private var imageURL: URL? {
        strMealThumb.flatMap(URL.init(string:))
    }

    private var thumbnailURL: URL? {
        imageURL?.appendingPathComponent("small")
    }

    var summary: MealSummary {
        MealSummary(id: idMeal, name: strMeal, thumbnailURL: thumbnailURL)
    }

    var detail: MealDetail {
        MealDetail(
            id: idMeal,
            name: strMeal,
            category: strCategory,
            area: strArea,
            instructions: strInstructions ?? "",
            imageURL: imageURL,
            thumbnailURL: thumbnailURL,
            youtubeURL: strYoutube.flatMap(URL.init(string:)),
            tags: strTags?.split(separator: ",").compactMap { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            ingredients: ingredients.map { Ingredient(name: $0.name, measure: $0.measure ?? "") }
        )
    }
}
