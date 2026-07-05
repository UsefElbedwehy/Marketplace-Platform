import Core

/// The auth flow's single entry point for `Presentation` — bundles sign-in/
/// sign-out/session-check rather than three near-empty pass-through use case
/// types, since none of the three carry extra business logic beyond the
/// repository call itself.
public protocol AuthUseCase: Sendable {
    func currentSession() async -> AuthSession?
    func signIn(as identity: DevIdentity) async throws -> AuthSession
    func signOut() async
}

public struct DefaultAuthUseCase: AuthUseCase {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func currentSession() async -> AuthSession? {
        await authRepository.currentSession()
    }

    public func signIn(as identity: DevIdentity) async throws -> AuthSession {
        try await authRepository.signIn(as: identity)
    }

    public func signOut() async {
        await authRepository.signOut()
    }
}
