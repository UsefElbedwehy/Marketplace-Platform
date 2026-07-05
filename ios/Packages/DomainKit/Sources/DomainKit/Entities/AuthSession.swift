/// One of the fixed dev identities seeded by
/// `backend/supabase/seed/02_dev_test_users.sql` — the iOS equivalent of the
/// dashboard's `DevIdentitySwitcher`. Real GoTrue-backed auth (email/OTP/Apple/
/// Google, ADR-0007) is unimplemented backend work; this is a like-for-like
/// stand-in so the app has something real to authenticate against, not a
/// screen with nothing behind it.
public struct DevIdentity: Equatable, Sendable, Identifiable {
    public let sub: String
    public let appRole: String
    public let displayName: String

    public var id: String { sub }

    public init(sub: String, appRole: String, displayName: String) {
        self.sub = sub
        self.appRole = appRole
        self.displayName = displayName
    }

    public static let all: [DevIdentity] = [
        DevIdentity(sub: "90000001-0000-0000-0000-000000000004", appRole: "admin", displayName: "Dev Admin"),
        DevIdentity(sub: "90000001-0000-0000-0000-000000000003", appRole: "catalog_editor", displayName: "Dev Catalog Editor"),
        DevIdentity(sub: "90000001-0000-0000-0000-000000000005", appRole: "moderator", displayName: "Dev Moderator"),
        DevIdentity(sub: "90000001-0000-0000-0000-000000000002", appRole: "seller", displayName: "Dev Seller"),
        DevIdentity(sub: "90000001-0000-0000-0000-000000000001", appRole: "buyer", displayName: "Dev Buyer"),
    ]
}

/// The authenticated session entity — mirrors the JWT claims RLS reads
/// (`sub`/`role`/`tenant_id`/`app_role`, docs/planning/08-api-auth.md §Part B).
public struct AuthSession: Equatable, Sendable {
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
