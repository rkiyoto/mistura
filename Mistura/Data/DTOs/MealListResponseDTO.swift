struct MealListResponseDTO: Decodable {
    let meals: [MealDTO]?

    private enum CodingKeys: String, CodingKey {
        case meals
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // A API responde "meals": null quando não há resultados; qualquer outro formato é erro
        guard container.contains(.meals), try !container.decodeNil(forKey: .meals) else {
            meals = nil
            return
        }

        var mealsContainer = try container.nestedUnkeyedContainer(forKey: .meals)
        var decodedMeals: [MealDTO] = []

        while !mealsContainer.isAtEnd {
            if let meal = try? mealsContainer.decode(MealDTO.self) {
                decodedMeals.append(meal)
            } else {
                _ = try? mealsContainer.decode(AnyCodable.self)
            }
        }
        meals = decodedMeals.isEmpty ? nil : decodedMeals
    }
}

private struct AnyCodable: Decodable {}
