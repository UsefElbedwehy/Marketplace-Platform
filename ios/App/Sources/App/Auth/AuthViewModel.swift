import Core
import DomainKit
import Observation

@Observable
@MainActor
final class AuthViewModel {
    private(set) var isSigningIn = false
    private(set) var errorMessage: String?

    @ObservationIgnored
    @Injected(\.authUseCase) private var authUseCase

    let identities = DevIdentity.all

    func signIn(as identity: DevIdentity) async -> Bool {
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }
        do {
            _ = try await authUseCase.signIn(as: identity)
            return true
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
            return false
        }
    }
}
