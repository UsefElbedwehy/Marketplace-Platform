/// Mirrors `configs/clients/<id>/theme.json` — the full semantic palette
/// (ADR-0005), typography scale, and shape tokens. `DesignSystem` builds its
/// `Theme` type directly from this DTO (it's allowed to depend on
/// `Configuration` for tokens — see 01-system-architecture.md §4).
public struct ThemeDTO: Codable, Equatable, Sendable {
    public struct SemanticColorSet: Codable, Equatable, Sendable {
        public let primary: String
        public let secondary: String
        public let accent: String
        public let background: String
        public let surface: String
        public let card: String
        public let border: String
        public let textPrimary: String
        public let textSecondary: String
        public let placeholder: String
        public let success: String
        public let warning: String
        public let danger: String
        public let info: String
        public let separator: String
        public let overlay: String
        public let skeleton: String
        public let loading: String
        public let selection: String
        public let navigation: String
        public let toolbar: String
        public let tabBar: String
        public let glass: String
        public let material: String
        public let interactive: String
        public let badge: String
        public let favorite: String
        public let online: String
        public let offline: String
    }

    public struct Colors: Codable, Equatable, Sendable {
        public let light: SemanticColorSet
        public let dark: SemanticColorSet
    }

    public struct TypeStyle: Codable, Equatable, Sendable {
        public let size: Double
        public let weight: String
        public let lineHeight: Double
    }

    public struct Typography: Codable, Equatable, Sendable {
        public let fontFamily: String
        public let scale: [String: TypeStyle]
    }

    public struct Shape: Codable, Equatable, Sendable {
        public let cornerRadiusSmall: Double
        public let cornerRadiusMedium: Double
        public let cornerRadiusLarge: Double
    }

    public let schemaFormatVersion: String
    public let clientId: String
    public let themeVersion: Int
    public let colors: Colors
    public let typography: Typography
    public let shape: Shape

    public init(
        schemaFormatVersion: String, clientId: String, themeVersion: Int, colors: Colors,
        typography: Typography, shape: Shape
    ) {
        self.schemaFormatVersion = schemaFormatVersion
        self.clientId = clientId
        self.themeVersion = themeVersion
        self.colors = colors
        self.typography = typography
        self.shape = shape
    }
}
