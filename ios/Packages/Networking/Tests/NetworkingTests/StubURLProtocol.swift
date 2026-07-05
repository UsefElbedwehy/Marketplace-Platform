import Foundation

/// Intercepts every request on a dedicated `URLSession` so `URLSessionAPIClient`
/// tests hit no real network — the standard `URLProtocol` stubbing technique.
final class StubURLProtocol: URLProtocol {
    struct Stub {
        let status: Int
        let headers: [String: String]
        let body: Data
    }

    nonisolated(unsafe) static var stub: Stub?
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static var session: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let stub = Self.stub else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: stub.status, httpVersion: "HTTP/1.1", headerFields: stub.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
