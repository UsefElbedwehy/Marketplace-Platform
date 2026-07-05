import Testing
@testable import DomainKit

@Test func authUseCaseReturnsNilWhenSignedOut() async {
    let repo = StubAuthRepository()
    let useCase = DefaultAuthUseCase(authRepository: repo)

    let session = await useCase.currentSession()

    #expect(session == nil)
}

@Test func authUseCaseSignInReturnsTheMintedSession() async throws {
    let repo = StubAuthRepository(signInResult: .success(.fixture(appRole: "admin")))
    let useCase = DefaultAuthUseCase(authRepository: repo)

    let session = try await useCase.signIn(as: DevIdentity.all[0])

    #expect(session.appRole == "admin")
    let current = await useCase.currentSession()
    #expect(current?.appRole == "admin")
}

@Test func authUseCaseSignOutClearsTheSession() async throws {
    let repo = StubAuthRepository(session: .fixture())
    let useCase = DefaultAuthUseCase(authRepository: repo)

    await useCase.signOut()

    let current = await useCase.currentSession()
    #expect(current == nil)
}
