import Core
import DesignSystem
import SwiftUI

/// Boot → Auth → Main, wrapped in exactly one `ThemedRoot` so the whole app
/// re-skins together the moment the theme loads or changes (ADR-0005).
struct RootView: View {
    @State private var coordinator = AppCoordinator(bootViewModel: BootViewModel())
    @InjectedObservable(\.themeStore) private var themeStore

    var body: some View {
        ThemedRoot(theme: themeStore.theme) {
            content
        }
        .task {
            await coordinator.start()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.root {
        case .booting:
            BootView()
        case .failed(let message):
            BootFailedView(message: message) {
                Task { await coordinator.start() }
            }
        case .auth:
            AuthView { coordinator.handleSignedIn() }
        case .main:
            MainTabView(coordinator: coordinator.tabCoordinator, appCoordinator: coordinator)
        }
    }
}

private struct BootView: View {
    @Environment(\.semanticColors) private var colors

    var body: some View {
        VStack(spacing: 16) {
            LoadingIndicator()
            Text("Marketplace Platform")
                .foregroundStyle(colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
    }
}

private struct BootFailedView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ErrorStateView(message: message, retry: retry)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
