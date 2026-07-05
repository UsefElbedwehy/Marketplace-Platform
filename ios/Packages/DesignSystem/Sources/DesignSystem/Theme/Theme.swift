import Configuration

/// Both color-scheme palettes plus typography/shape — the full result of
/// resolving a `ThemeDTO`. `ThemedRoot` picks `light` or `dark` based on the
/// live `colorScheme` and injects it into `\.semanticColors`.
public struct Theme: Equatable {
    public let clientId: String
    public let version: Int
    public let light: SemanticColors
    public let dark: SemanticColors
    public let typography: Typography
    public let shape: ThemeShape

    public static func resolve(from dto: ThemeDTO) -> Theme {
        Theme(
            clientId: dto.clientId,
            version: dto.themeVersion,
            light: .resolve(from: dto.colors.light),
            dark: .resolve(from: dto.colors.dark),
            typography: .resolve(from: dto.typography),
            shape: .resolve(from: dto.shape)
        )
    }
}
