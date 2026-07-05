import Core
@testable import DomainKit

struct StubConfigRepository: ConfigRepository {
    var result: Result<AppConfiguration, Error>

    func fetchConfiguration() async throws -> AppConfiguration {
        try result.get()
    }
}

actor StubAuthRepository: AuthRepository {
    private var session: AuthSession?
    private var signInResult: Result<AuthSession, Error>
    private(set) var signOutCallCount = 0

    init(session: AuthSession? = nil, signInResult: Result<AuthSession, Error> = .failure(CancellationError())) {
        self.session = session
        self.signInResult = signInResult
    }

    func currentSession() -> AuthSession? { session }

    func signIn(as identity: DevIdentity) async throws -> AuthSession {
        let session = try signInResult.get()
        self.session = session
        return session
    }

    func signOut() {
        session = nil
        signOutCallCount += 1
    }
}

extension AppConfiguration {
    static func fixture(clientId: String = "default") -> AppConfiguration {
        AppConfiguration(
            schemaVersion: "1.0.0",
            clientId: clientId,
            locales: .init(supported: [.english, .arabic], defaultLocale: .english),
            currencies: ["SAR", "USD"],
            defaultCurrency: "SAR",
            modules: .init(
                authentication: true, listings: true, search: true, favorites: true, chat: true,
                notifications: true, sellerDashboard: true, subscriptions: false, payments: false,
                wallet: false, advertisements: false, reviews: true, moderation: true
            ),
            featureFlags: [:],
            support: .init(email: "support@example.com", phone: nil, chatEnabled: true)
        )
    }
}

extension AuthSession {
    static func fixture(sub: String = "90000001-0000-0000-0000-000000000001", appRole: String = "buyer") -> AuthSession {
        AuthSession(accessToken: "token", sub: sub, tenantId: "00000000-0000-0000-0000-000000000001", appRole: appRole, displayName: "Dev Buyer")
    }
}
