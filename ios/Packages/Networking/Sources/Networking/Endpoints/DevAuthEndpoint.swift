import Foundation

/// `POST /v1/dev-auth` — deliberately excluded from `contract/openapi`
/// (backend/supabase/functions/v1-dev-auth), a local-only JWT minter standing
/// in for real GoTrue-backed auth. Kept as a one-off endpoint here rather than
/// a generic "contract codegen" path since it must never ship to production.
public enum DevAuthEndpoint {
    private struct RequestBody: Encodable {
        let sub: String
        let role: String
        let tenant_id: String
        let app_role: String
    }

    public static func signIn(sub: String, tenantId: String, appRole: String) throws -> APIEndpoint {
        try APIEndpoint.encoding(
            RequestBody(sub: sub, role: "authenticated", tenant_id: tenantId, app_role: appRole),
            path: "/v1/dev-auth",
            method: .post,
            requiresAuth: false
        )
    }
}

public struct DevAuthResponse: Decodable, Sendable {
    public let accessToken: String

    public init(accessToken: String) {
        self.accessToken = accessToken
    }
}
