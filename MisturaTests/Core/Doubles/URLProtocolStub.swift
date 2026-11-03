import Foundation

nonisolated final class URLProtocolStub: URLProtocol {
    nonisolated(unsafe) static var result: Result<(statusCode: Int, data: Data), Error> = .success((200, Data()))
    nonisolated(unsafe) static var requestedURLs: [URL] = []

    static func makeSession() -> URLSession {
        requestedURLs = []
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else { return }
        Self.requestedURLs.append(url)

        switch Self.result {
        case .success(let stubbed):
            let response = HTTPURLResponse(
                url: url,
                statusCode: stubbed.statusCode,
                httpVersion: nil,
                headerFields: nil
            )
            client?.urlProtocol(self, didReceive: response ?? URLResponse(), cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: stubbed.data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
