import Core
import Foundation

/// The concrete `APIClient`: plain `URLSession` against the Edge Functions
/// gateway. No Supabase SDK involved — v1 auth is `/v1/dev-auth` (see
/// `DevIdentity`'s doc comment in DomainKit), so there is nothing to isolate
/// yet beyond this file itself.
///
/// **On 401:** there is no refresh endpoint yet (real GoTrue-backed auth is
/// unimplemented backend work — docs/planning/08-api-auth.md §Part B), so
/// this does not attempt a single-flight token refresh. It calls
/// `onSessionExpired` so the composition root can react (e.g. force sign-out)
/// instead of silently retrying against an endpoint that doesn't exist.
public final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: TokenStore
    private let logger: AppLogger
    private let onSessionExpired: (@Sendable () async -> Void)?

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenStore: TokenStore,
        logger: AppLogger = OSAppLogger.shared,
        onSessionExpired: (@Sendable () async -> Void)? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
        self.logger = logger
        self.onSessionExpired = onSessionExpired
    }

    public func send<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingTo type: T.Type) async throws -> APIResponse<T> {
        let outcome = try await performRequest(endpoint)
        switch outcome {
        case .notModified(let etag):
            return APIResponse(value: nil, etag: etag, notModified: true)
        case .ok(let data, let etag):
            do {
                let decoded = try JSONDecoder().decode(SuccessEnvelope<T>.self, from: data)
                return APIResponse(value: decoded.data, etag: etag, notModified: false)
            } catch {
                logger.error("Failed to decode \(T.self) from \(endpoint.path): \(error)", category: "networking")
                throw DomainError.decoding
            }
        }
    }

    /// The collection envelope (docs/planning/08-api-auth.md §3: `{"data":
    /// [...], "page": {...}}`) is a *different* shape from the single-item
    /// `{"data": T}` `send` decodes — `page` is a sibling of `data`, not
    /// nested under it, so it can't be recovered by just picking `T = [Item]`
    /// in `send`. This is that second shape's decode path.
    public func sendCollection<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingItemsTo type: T.Type) async throws -> (items: [T], page: PaginationMeta) {
        let outcome = try await performRequest(endpoint)
        switch outcome {
        case .notModified:
            throw DomainError.unknown(message: "Unexpected 304 for a non-conditional collection request.")
        case .ok(let data, _):
            do {
                let decoded = try JSONDecoder().decode(CollectionEnvelope<T>.self, from: data)
                return (decoded.data, decoded.page)
            } catch {
                logger.error("Failed to decode collection of \(T.self) from \(endpoint.path): \(error)", category: "networking")
                throw DomainError.decoding
            }
        }
    }

    public func sendNoContent(_ endpoint: APIEndpoint) async throws {
        _ = try await performRequest(endpoint)
    }

    private enum RequestOutcome {
        case ok(data: Data, etag: String?)
        case notModified(etag: String?)
    }

    private func performRequest(_ endpoint: APIEndpoint) async throws -> RequestOutcome {
        let request = try await buildRequest(for: endpoint)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            logger.warning("\(endpoint.method.rawValue) \(endpoint.path) failed: \(error.code)", category: "networking")
            throw error.code == .notConnectedToInternet || error.code == .networkConnectionLost ? DomainError.offline : DomainError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw DomainError.unknown(message: "Non-HTTP response")
        }

        if http.statusCode == 304 {
            return .notModified(etag: http.value(forHeaderField: "ETag"))
        }

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 {
                await onSessionExpired?()
            }
            throw mapError(status: http.statusCode, data: data)
        }

        return .ok(data: data, etag: http.value(forHeaderField: "ETag"))
    }

    private func buildRequest(for endpoint: APIEndpoint) async throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        if !endpoint.queryItems.isEmpty { components?.queryItems = endpoint.queryItems }
        guard let url = components?.url else { throw DomainError.unknown(message: "Invalid URL for \(endpoint.path)") }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        if let etag = endpoint.ifNoneMatch { request.setValue(etag, forHTTPHeaderField: "If-None-Match") }

        if endpoint.requiresAuth, let session = await tokenStore.load() {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "authorization")
        }
        return request
    }

    private func mapError(status: Int, data: Data) -> DomainError {
        let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data)
        switch status {
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 409: return .conflict
        case 422:
            let fields = (envelope?.error.fields ?? []).map { FieldError(field: $0.field, code: $0.code, message: $0.message) }
            return .validation(fields)
        case 429: return .rateLimited
        case 500...599: return .server
        default: return .unknown(message: envelope?.error.message ?? "Request failed (\(status))")
        }
    }
}

extension HTTPURLResponse {
    fileprivate func value(forHeaderField field: String) -> String? {
        (allHeaderFields as? [String: String])?.first(where: { $0.key.caseInsensitiveCompare(field) == .orderedSame })?.value
    }
}
