import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A value describing one contract operation (docs/planning/08-api-auth.md
/// §4) — method, path, query, body, auth requirement, conditional-GET support.
public struct APIEndpoint: Sendable {
    public var path: String
    public var method: HTTPMethod
    public var queryItems: [URLQueryItem]
    public var body: Data?
    public var requiresAuth: Bool
    public var ifNoneMatch: String?

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        requiresAuth: Bool = true,
        ifNoneMatch: String? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.requiresAuth = requiresAuth
        self.ifNoneMatch = ifNoneMatch
    }

    public static func encoding<Body: Encodable>(
        _ body: Body,
        path: String,
        method: HTTPMethod,
        requiresAuth: Bool = true
    ) throws -> APIEndpoint {
        let data = try JSONEncoder().encode(body)
        return APIEndpoint(path: path, method: method, body: data, requiresAuth: requiresAuth)
    }
}
