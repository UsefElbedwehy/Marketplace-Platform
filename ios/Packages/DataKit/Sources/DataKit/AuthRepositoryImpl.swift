import Core
import DomainKit
import Networking

/// Fulfils `DomainKit.AuthRepository` — mints a session via `/v1/dev-auth`
/// (`Networking.DevAuthEndpoint`, standing in for real GoTrue-backed auth,
/// see `DevIdentity`'s doc comment) and persists it via the Keychain-backed
/// `TokenStore`. The only place `StoredSession` (`Networking`) and
/// `AuthSession` (`DomainKit`) are translated into one another.
public struct AuthRepositoryImpl: AuthRepository {
    private let apiClient: APIClient
    private let tokenStore: TokenStore
    private let tenantId: String

    public init(apiClient: APIClient, tokenStore: TokenStore, tenantId: String) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.tenantId = tenantId
    }

    public func currentSession() async -> AuthSession? {
        await tokenStore.load().map(Self.map)
    }

    public func signIn(as identity: DevIdentity) async throws -> AuthSession {
        let endpoint = try DevAuthEndpoint.signIn(sub: identity.sub, tenantId: tenantId, appRole: identity.appRole)
        let response: DevAuthResponse
        do {
            response = try await apiClient.send(endpoint, decodingTo: DevAuthResponse.self)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }

        let stored = StoredSession(
            accessToken: response.accessToken,
            sub: identity.sub,
            tenantId: tenantId,
            appRole: identity.appRole,
            displayName: identity.displayName
        )
        try await tokenStore.save(stored)
        return Self.map(stored)
    }

    public func signOut() async {
        await tokenStore.clear()
    }

    private static func map(_ stored: StoredSession) -> AuthSession {
        AuthSession(
            accessToken: stored.accessToken,
            sub: stored.sub,
            tenantId: stored.tenantId,
            appRole: stored.appRole,
            displayName: stored.displayName
        )
    }
}
