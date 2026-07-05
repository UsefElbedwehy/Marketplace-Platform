import Foundation

/// Mirrors the API contract's standard success envelope
/// (docs/planning/08-api-auth.md §3): `{"data": ...}`.
struct SuccessEnvelope<T: Decodable>: Decodable {
    let data: T
}

/// The contract's cursor-pagination metadata (`docs/planning/08-api-auth.md`
/// §3's "collection" envelope) — a page of any resource, not catalog/listings-
/// specific, so it lives here rather than in a DataKit DTO.
public struct PaginationMeta: Decodable, Sendable, Equatable {
    public let nextCursor: String?
    public let hasMore: Bool
}

/// Mirrors the collection envelope: `{"data": [...], "page": {...}}` — `page`
/// is a *sibling* of `data`, not nested under it, so it needs its own decode
/// path distinct from `SuccessEnvelope<[T]>` (which would silently drop it).
struct CollectionEnvelope<T: Decodable>: Decodable {
    let data: [T]
    let page: PaginationMeta
}

/// Mirrors the standard error envelope: `{"error": {code, message, fields?}}`.
struct ErrorEnvelope: Decodable {
    struct Body: Decodable {
        let code: String
        let message: String
        let fields: [FieldErrorDTO]?
    }
    struct FieldErrorDTO: Decodable {
        let field: String
        let code: String
        let message: String
    }
    let error: Body
}
