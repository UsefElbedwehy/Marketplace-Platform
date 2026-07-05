import Core

/// The boot sequence's config half (docs/planning/11-roadmap.md Phase 3 exit
/// criteria: "boots, fetches config+theme"). Theme fetching is deliberately
/// not modeled here — it's a `Configuration`/`DesignSystem`-only concern with
/// no business logic (see DesignSystem's `ThemeStore`); the App composition
/// root runs this use case and the theme load concurrently via `async let`.
public protocol FetchBootstrapConfigUseCase: Sendable {
    func execute() async throws -> AppConfiguration
}

public struct DefaultFetchBootstrapConfigUseCase: FetchBootstrapConfigUseCase {
    private let configRepository: ConfigRepository

    public init(configRepository: ConfigRepository) {
        self.configRepository = configRepository
    }

    public func execute() async throws -> AppConfiguration {
        try await configRepository.fetchConfiguration()
    }
}
