import Core
import Foundation

/// `value` is nil exactly when the server answered 304 (conditional GET,
/// `?ifNoneMatch` echoed back) — the caller already has the freshest copy.
public struct APIResponse<T: Sendable>: Sendable {
    public let value: T?
    public let etag: String?
    public let notModified: Bool

    public init(value: T?, etag: String?, notModified: Bool) {
        self.value = value
        self.etag = etag
        self.notModified = notModified
    }
}

/// `UseCase → Repository → APIClient → APIEndpoint` (docs/planning/08-api-auth.md
/// §4) — the seam that protects portability. No Supabase type crosses it.
public protocol APIClient: Sendable {
    func send<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingTo type: T.Type) async throws -> APIResponse<T>

    /// For the collection envelope (`{"data": [...], "page": {...}}`) —
    /// `page` is a sibling of `data`, so `send` (built for `{"data": T}`)
    /// can't recover it even with `T = [Item]`. See `PaginationMeta`.
    func sendCollection<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingItemsTo type: T.Type) async throws -> (items: [T], page: PaginationMeta)

    /// For endpoints with no response body at all (e.g. `DELETE /v1/favorites/{id}`
    /// returning 204) — `send`'s `SuccessEnvelope<T>` decode would fail
    /// against an empty body since there's no `{"data": ...}` to find.
    func sendNoContent(_ endpoint: APIEndpoint) async throws
}

extension APIClient {
    /// Convenience for the common case: no conditional-GET handling, just the
    /// decoded value or a thrown `DomainError`.
    public func send<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingTo type: T.Type) async throws -> T {
        let response: APIResponse<T> = try await send(endpoint, decodingTo: type)
        guard let value = response.value else {
            throw DomainError.unknown(message: "Expected a body but the server returned 304 for a non-conditional request.")
        }
        return value
    }
}
