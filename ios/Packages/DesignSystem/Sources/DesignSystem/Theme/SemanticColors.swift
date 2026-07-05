import SwiftUI
import Configuration

/// The semantic color vocabulary views read (ADR-0005) — never a raw literal.
/// One instance per color scheme; `ThemedRoot` picks the active one and
/// injects it into `\.semanticColors` reactively as `colorScheme` changes.
public struct SemanticColors: Equatable {
    public let primary: Color
    public let secondary: Color
    public let accent: Color
    public let background: Color
    public let surface: Color
    public let card: Color
    public let border: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let placeholder: Color
    public let success: Color
    public let warning: Color
    public let danger: Color
    public let info: Color
    public let separator: Color
    public let overlay: Color
    public let skeleton: Color
    public let loading: Color
    public let selection: Color
    public let navigation: Color
    public let toolbar: Color
    public let tabBar: Color
    public let glass: Color
    public let material: Color
    public let interactive: Color
    public let badge: Color
    public let favorite: Color
    public let online: Color
    public let offline: Color

    /// A loud, unmistakable placeholder used only when a hex string fails to
    /// parse — visible-in-review is better than a silent fallback to black.
    static let malformedHexPlaceholder = Color(.sRGB, red: 1, green: 0, blue: 1, opacity: 1)

    static func resolve(from set: ThemeDTO.SemanticColorSet) -> SemanticColors {
        func color(_ hex: String) -> Color { Color(hex: hex) ?? malformedHexPlaceholder }
        return SemanticColors(
            primary: color(set.primary),
            secondary: color(set.secondary),
            accent: color(set.accent),
            background: color(set.background),
            surface: color(set.surface),
            card: color(set.card),
            border: color(set.border),
            textPrimary: color(set.textPrimary),
            textSecondary: color(set.textSecondary),
            placeholder: color(set.placeholder),
            success: color(set.success),
            warning: color(set.warning),
            danger: color(set.danger),
            info: color(set.info),
            separator: color(set.separator),
            overlay: color(set.overlay),
            skeleton: color(set.skeleton),
            loading: color(set.loading),
            selection: color(set.selection),
            navigation: color(set.navigation),
            toolbar: color(set.toolbar),
            tabBar: color(set.tabBar),
            glass: color(set.glass),
            material: color(set.material),
            interactive: color(set.interactive),
            badge: color(set.badge),
            favorite: color(set.favorite),
            online: color(set.online),
            offline: color(set.offline)
        )
    }
}
