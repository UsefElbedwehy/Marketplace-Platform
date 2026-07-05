import Core
import DesignSystem
import DomainKit
import Observation

/// The root coordinator (docs/planning/02-ios-architecture.md §2): owns which
/// top-level scene is shown (boot / auth / main) and composes the
/// `TabCoordinator` for the signed-in state. ViewModels below it never touch
/// navigation directly — they emit state, this coordinator (and its
/// children) turn that into what's on screen.
@Observable
@MainActor
final class AppCoordinator {
    enum Root: Equatable {
        case booting
        case auth
        case main
        case failed(String)
    }

    private(set) var root: Root = .booting
    private(set) var config: AppConfiguration?

    let bootViewModel: BootViewModel
    let tabCoordinator = TabCoordinator()

    @ObservationIgnored
    @Injected(\.authUseCase) private var authUseCase
    @ObservationIgnored
    @Injected(\.themeStore) private var themeStore

    init(bootViewModel: BootViewModel) {
        self.bootViewModel = bootViewModel
    }

    /// Fetches config and theme **concurrently** (roadmap Phase 3 exit
    /// criteria) via structured concurrency — config through the use case,
    /// theme through `DesignSystem`'s store directly (see `ThemeStore`'s doc
    /// comment on why theme has no DomainKit repository of its own).
    func start() async {
        async let configTask: Void = bootViewModel.boot()
        async let themeTask: Void = themeStore.load()
        _ = await (configTask, themeTask)

        switch bootViewModel.state {
        case .ready(let config):
            self.config = config
            let session = await authUseCase.currentSession()
            root = session != nil ? .main : .auth
        case .failed(let message):
            root = .failed(message)
        case .loading:
            break
        }
    }

    func handleSignedIn() {
        root = .main
    }

    func signOut() async {
        await authUseCase.signOut()
        root = .auth
    }
}
