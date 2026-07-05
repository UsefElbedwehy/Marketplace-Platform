import Configuration
import Foundation

/// The App composition root's handle on "what theme is currently active."
/// Deliberately outside `DomainKit`/`DataKit` — theme has no business logic,
/// it's a `Configuration` → `DesignSystem` concern end to end (see
/// `docs/planning/02-ios-architecture.md` §9 and this package's dependency
/// table: DesignSystem may depend on Configuration directly).
@Observable
@MainActor
public final class ThemeStore {
    public private(set) var theme: Theme

    private let dataSource: ConfigurationDataSource

    public init(dataSource: ConfigurationDataSource, initial: Theme = ThemeStore.placeholder) {
        self.dataSource = dataSource
        self.theme = initial
    }

    /// Fetches (cache-then-network, ADR-0013) and republishes the theme —
    /// called once at boot and again whenever Theme Studio publishes a new
    /// version and the app wants to pick it up (pull-to-refresh / foreground).
    public func load() async {
        guard let dto = try? await dataSource.loadTheme() else { return }
        theme = .resolve(from: dto)
    }

    // Pure value computation over Sendable data — no actual actor-isolated
    // state involved, so this doesn't need (and shouldn't inherit) the
    // class's @MainActor isolation; a default-parameter value must be
    // evaluatable from a nonisolated context.
    nonisolated public static let placeholder = Theme.resolve(from: try! BundledDefaults.theme())
}
