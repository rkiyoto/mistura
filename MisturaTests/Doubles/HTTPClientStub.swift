import Foundation
@testable import Mistura

final class HTTPClientStub: HTTPClient {
    var result: Result<Data, Error> = .success(Data())

    private(set) var requestedURLs: [URL] = []

    func makeRequest(from url: URL) async throws -> Data {
        requestedURLs.append(url)
        return try result.get()
    }
}
