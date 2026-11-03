import Foundation

enum MealService {
    case searchByName(String)
    case filterByIngredient(String)
    case lookup(id: String)

    private static let baseURL = URL(string: "https://www.themealdb.com/api/json/v1/1/")! // 1 is public key

    var url: URL? {
        var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [queryItem]
        return components?.url
    }

    private var path: String {
        switch self {
        case .searchByName: "search.php"
        case .filterByIngredient: "filter.php"
        case .lookup: "lookup.php"
        }
    }

    private var queryItem: URLQueryItem {
        switch self {
        case .searchByName(let name):
            URLQueryItem(name: "s", value: name)
        case .filterByIngredient(let ingredient):
            URLQueryItem(name: "i", value: ingredient.lowercased().replacingOccurrences(of: " ", with: "_"))
        case .lookup(let id):
            URLQueryItem(name: "i", value: id)
        }
    }
}
