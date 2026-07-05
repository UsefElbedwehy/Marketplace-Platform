import Foundation

/// Where this build talks to. Defaults to the local dev gateway
/// (`backend/scripts/serve-local.ts`, port 8000) — matches the dashboard's
/// `NEXT_PUBLIC_API_BASE_URL` convention. Override via the `API_BASE_URL`
/// build setting / environment for a real deployment.
enum AppEnvironment {
    static var apiBaseURL: URL {
        if let override = ProcessInfo.processInfo.environment["API_BASE_URL"], let url = URL(string: override) {
            return url
        }
        return URL(string: "http://localhost:8000")!
    }

    /// Single-tenant-per-deployment (ADR-0011) — the tenant this build talks
    /// to, matching `backend/supabase/seed`'s default tenant.
    static let tenantId = "00000000-0000-0000-0000-000000000001"
}
