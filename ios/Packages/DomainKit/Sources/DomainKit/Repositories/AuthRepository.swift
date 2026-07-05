import Core

/// Fulfilled in `DataKit`, backed by `Networking`'s dev-auth client + Keychain
/// `TokenStore` (real GoTrue-backed auth is unimplemented backend work — see
/// `DevIdentity`'s doc comment).
public protocol AuthRepository: Sendable {
    func currentSession() async -> AuthSession?
    func signIn(as identity: DevIdentity) async throws -> AuthSession
    func signOut() async
}
