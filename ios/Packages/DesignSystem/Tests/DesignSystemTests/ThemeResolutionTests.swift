import Testing
@testable import Configuration
@testable import DesignSystem

func makeColorSet(primary: String = "#2563EB") -> ThemeDTO.SemanticColorSet {
    ThemeDTO.SemanticColorSet(
        primary: primary, secondary: "#64748B", accent: "#F59E0B", background: "#FFFFFF",
        surface: "#F8FAFC", card: "#FFFFFF", border: "#E2E8F0", textPrimary: "#0F172A",
        textSecondary: "#475569", placeholder: "#94A3B8", success: "#16A34A", warning: "#F59E0B",
        danger: "#DC2626", info: "#0EA5E9", separator: "#E2E8F0", overlay: "#0F172A99",
        skeleton: "#E2E8F0", loading: "#2563EB", selection: "#DBEAFE", navigation: "#FFFFFF",
        toolbar: "#FFFFFF", tabBar: "#FFFFFF", glass: "#FFFFFFCC", material: "#F1F5F9",
        interactive: "#2563EB", badge: "#DC2626", favorite: "#E11D48", online: "#16A34A", offline: "#94A3B8"
    )
}

@Test func themeResolveCarriesClientIdAndVersion() {
    let dto = ThemeDTO(
        schemaFormatVersion: "1.0.0", clientId: "client_a", themeVersion: 5,
        colors: .init(light: makeColorSet(), dark: makeColorSet(primary: "#3B82F6")),
        typography: .init(fontFamily: "Inter", scale: [:]),
        shape: .init(cornerRadiusSmall: 4, cornerRadiusMedium: 8, cornerRadiusLarge: 16)
    )

    let theme = Theme.resolve(from: dto)

    #expect(theme.clientId == "client_a")
    #expect(theme.version == 5)
    #expect(theme.light != theme.dark)
}

@Test func typographyFallsBackToSystemFontWhenAScaleKeyIsMissing() {
    let typography = Typography.resolve(from: .init(fontFamily: "Inter", scale: [:]))

    #expect(typography.body.lineHeight == 17 * 1.2)
}

@Test func typographyUsesTheDeclaredScaleWhenPresent() {
    let dto = ThemeDTO.Typography(fontFamily: "Inter", scale: ["body": .init(size: 17, weight: "regular", lineHeight: 22)])

    let typography = Typography.resolve(from: dto)

    #expect(typography.body.lineHeight == 22)
}

@Test func shapeResolvesCornerRadiiDirectly() {
    let shape = ThemeShape.resolve(from: .init(cornerRadiusSmall: 4, cornerRadiusMedium: 8, cornerRadiusLarge: 16))

    #expect(shape.cornerRadiusSmall == 4)
    #expect(shape.cornerRadiusLarge == 16)
}
