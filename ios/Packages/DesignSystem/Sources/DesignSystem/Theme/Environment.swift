import SwiftUI
import Configuration

private struct ThemeKey: EnvironmentKey {
    /// A crash-if-missing default, deliberately: the bundled default theme
    /// resource is a build-time invariant (`Configuration`'s `BundledDefaults`),
    /// not something we should silently limp along without.
    static let defaultValue = Theme.resolve(from: try! BundledDefaults.theme())
}

private struct SemanticColorsKey: EnvironmentKey {
    static let defaultValue = ThemeKey.defaultValue.light
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }

    /// Always the palette resolved for the *current* color scheme — this is
    /// what components read (`\.semanticColors.primary`, never `\.theme.light`
    /// directly), so light/dark just works without every call site branching
    /// on `colorScheme` itself.
    public var semanticColors: SemanticColors {
        get { self[SemanticColorsKey.self] }
        set { self[SemanticColorsKey.self] = newValue }
    }
}

/// Injects a `Theme` into the environment and keeps `\.semanticColors` synced
/// to the live `colorScheme` — the mechanism behind ADR-0005's "themes ...
/// hot-swappable" and "restyles the whole app" guarantees. Wrap the app's
/// root view in exactly one of these (the App composition root).
public struct ThemedRoot<Content: View>: View {
    let theme: Theme
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content

    public init(theme: Theme, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    public var body: some View {
        let resolvedColors = colorScheme == .dark ? theme.dark : theme.light
        content
            .environment(\.theme, theme)
            .environment(\.semanticColors, resolvedColors)
            // Applied at the true root (not per-screen) so it reaches system
            // chrome too (e.g. the tab bar's selected-item color) — a `.tint`
            // set only on a child view can miss UIKit-backed chrome that
            // reads the window's tint directly.
            .tint(resolvedColors.primary)
    }
}
