import Foundation

/// The single error taxonomy every layer above `Networking` deals in
/// (docs/planning/02-ios-architecture.md §8). `Networking` maps HTTP/transport
/// failures and the standard API error envelope into this; `Presentation`
/// maps this into localized, themed UI states. Nothing above `Networking`
/// should ever see a raw `URLError` or `DecodingError`.
public enum DomainError: Error, Equatable, Sendable {
    case network
    case unauthorized
    case forbidden
    case notFound
    case validation([FieldError])
    case conflict
    case rateLimited
    case server
    case offline
    case decoding
    case unknown(message: String)
}

/// Mirrors the API contract's `error.fields[]` (docs/planning/08-api-auth.md
/// §3) so a validation failure maps field-by-field back onto a dynamic form.
public struct FieldError: Equatable, Sendable, Identifiable {
    public let field: String
    public let code: String
    public let message: String

    public var id: String { field + code }

    public init(field: String, code: String, message: String) {
        self.field = field
        self.code = code
        self.message = message
    }
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .network: return "A network error occurred. Please check your connection."
        case .unauthorized: return "You need to sign in to do that."
        case .forbidden: return "You don't have permission to do that."
        case .notFound: return "We couldn't find what you were looking for."
        case .validation(let fields): return fields.first?.message ?? "Some fields need attention."
        case .conflict: return "That already exists."
        case .rateLimited: return "Too many attempts. Please wait and try again."
        case .server: return "Something went wrong on our end."
        case .offline: return "You're offline."
        case .decoding: return "We received an unexpected response."
        case .unknown(let message): return message
        }
    }
}
