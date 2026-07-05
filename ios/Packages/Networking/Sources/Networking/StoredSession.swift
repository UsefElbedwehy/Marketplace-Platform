/// The Keychain-persisted shape of a session (ADR-0007 / docs/planning/
/// 08-api-auth.md §2: "Stored in Keychain, never SwiftData/UserDefaults").
/// `DataKit`'s `AuthRepositoryImpl` maps this to/from `DomainKit.AuthSession`
/// — `Networking` doesn't know about `DomainKit` at all.
public struct StoredSession: Codable, Equatable, Sendable {
    public let accessToken: String
    public let sub: String
    public let tenantId: String
    public let appRole: String
    public let displayName: String

    public init(accessToken: String, sub: String, tenantId: String, appRole: String, displayName: String) {
        self.accessToken = accessToken
        self.sub = sub
        self.tenantId = tenantId
        self.appRole = appRole
        self.displayName = displayName
    }
}
