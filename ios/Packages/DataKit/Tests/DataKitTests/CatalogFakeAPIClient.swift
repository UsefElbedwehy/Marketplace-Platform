import Networking

/// A general-purpose fake `APIClient` for `CategoryRepositoryImpl`/
/// `ListingRepositoryImpl` tests — routes by matching a substring of the
/// endpoint path, since these repositories hit several distinct paths.
final class RoutedFakeAPIClient: APIClient, @unchecked Sendable {
    struct Route {
        let pathContains: String
        var value: (any Sendable)?
        var collection: (items: [any Sendable], page: PaginationMeta)?
        var error: Error?
    }

    var routes: [Route]
    private(set) var lastPath: String?
    private(set) var lastRequiredAuth: Bool?

    init(routes: [Route]) {
        self.routes = routes
    }

    func send<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingTo type: T.Type) async throws -> APIResponse<T> {
        lastPath = endpoint.path
        lastRequiredAuth = endpoint.requiresAuth
        guard let route = routes.first(where: { endpoint.path.contains($0.pathContains) }) else {
            fatalError("no route configured for \(endpoint.path)")
        }
        if let error = route.error { throw error }
        return APIResponse(value: (route.value as! T), etag: nil, notModified: false)
    }

    func sendCollection<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingItemsTo type: T.Type) async throws -> (items: [T], page: PaginationMeta) {
        lastPath = endpoint.path
        lastRequiredAuth = endpoint.requiresAuth
        guard let route = routes.first(where: { endpoint.path.contains($0.pathContains) }) else {
            fatalError("no route configured for \(endpoint.path)")
        }
        if let error = route.error { throw error }
        let (items, page) = route.collection!
        return (items.map { $0 as! T }, page)
    }

    func sendNoContent(_ endpoint: APIEndpoint) async throws {
        lastPath = endpoint.path
        lastRequiredAuth = endpoint.requiresAuth
        guard let route = routes.first(where: { endpoint.path.contains($0.pathContains) }) else {
            fatalError("no route configured for \(endpoint.path)")
        }
        if let error = route.error { throw error }
    }
}
