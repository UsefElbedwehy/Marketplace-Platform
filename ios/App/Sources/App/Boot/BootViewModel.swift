import Core
import DomainKit
import Observation

enum BootState: Equatable {
    case loading
    case ready(AppConfiguration)
    case failed(String)
}

/// The config half of the boot sequence — `AppCoordinator.start()` runs this
/// concurrently with `DesignSystem.ThemeStore.load()` via `async let`
/// (docs/planning/11-roadmap.md Phase 3 exit criteria: "boots, fetches
/// config+theme"). Theme isn't tracked here since it's not a business concern
/// (see `ThemeStore`'s doc comment) — it lives entirely in the Configuration
/// → DesignSystem lane.
@Observable
@MainActor
final class BootViewModel {
    private(set) var state: BootState = .loading

    @ObservationIgnored
    @Injected(\.fetchBootstrapConfigUseCase) private var fetchBootstrapConfig

    func boot() async {
        state = .loading
        do {
            let config = try await fetchBootstrapConfig.execute()
            state = .ready(config)
        } catch {
            state = .failed((error as? DomainError)?.errorDescription ?? "\(error)")
        }
    }
}
