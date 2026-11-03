import Foundation
import Nimble
import Quick
@testable import Mistura

nonisolated final class URLSessionHTTPClientTests: AsyncSpec {
    override class func spec() {
        nonisolated(unsafe) var sut: URLSessionHTTPClient!

        let url = URL(string: "https://example.com/meals")!

        beforeEach { @MainActor in
            URLProtocolStub.result = .success((200, Data()))
            sut = URLSessionHTTPClient(session: URLProtocolStub.makeSession())
        }

        describe("makeRequest") {
            it("requests the given URL") { @MainActor in
                _ = try await sut.makeRequest(from: url)

                expect(URLProtocolStub.requestedURLs).to(equal([url]))
            }

            it("returns the data of a successful response") { @MainActor in
                URLProtocolStub.result = .success((200, Data("soup".utf8)))

                let data = try await sut.makeRequest(from: url)

                expect(data).to(equal(Data("soup".utf8)))
            }

            it("accepts the last status code of the success range") { @MainActor in
                URLProtocolStub.result = .success((299, Data("soup".utf8)))

                let data = try await sut.makeRequest(from: url)

                expect(data).to(equal(Data("soup".utf8)))
            }

            for statusCode in [199, 300, 404, 500] {
                it("throws invalidResponse for status code \(statusCode)") { @MainActor in
                    URLProtocolStub.result = .success((statusCode, Data()))

                    let error = await captureError { try await sut.makeRequest(from: url) }

                    expect(error).to(matchError(NetworkError.invalidResponse))
                }
            }

            it("propagates a transport failure") { @MainActor in
                URLProtocolStub.result = .failure(URLError(.notConnectedToInternet))

                let error = await captureError { try await sut.makeRequest(from: url) }

                expect((error as? URLError)?.code).to(equal(.notConnectedToInternet))
            }
        }
    }
}

