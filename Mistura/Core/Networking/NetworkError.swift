import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decoding(Error)
}
