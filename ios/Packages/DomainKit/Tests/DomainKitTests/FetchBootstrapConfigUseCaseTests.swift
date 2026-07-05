import Testing
@testable import DomainKit

@Test func fetchBootstrapConfigReturnsRepositoryResult() async throws {
    let repo = StubConfigRepository(result: .success(.fixture(clientId: "client_a")))
    let useCase = DefaultFetchBootstrapConfigUseCase(configRepository: repo)

    let config = try await useCase.execute()

    #expect(config.clientId == "client_a")
}

@Test func fetchBootstrapConfigPropagatesRepositoryFailure() async {
    struct Boom: Error {}
    let repo = StubConfigRepository(result: .failure(Boom()))
    let useCase = DefaultFetchBootstrapConfigUseCase(configRepository: repo)

    await #expect(throws: Boom.self) {
        try await useCase.execute()
    }
}
