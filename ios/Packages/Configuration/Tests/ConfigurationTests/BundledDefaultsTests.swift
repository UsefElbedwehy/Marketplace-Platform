import Testing
@testable import Configuration

@Test func bundledDefaultConfigDecodesFromTheRealDefaultClientJSON() throws {
    let config = try BundledDefaults.config()

    #expect(config.clientId == "default")
    #expect(config.locales.supported.contains("ar"))
    #expect(config.locales.rtlLocales == ["ar"])
}

@Test func bundledDefaultThemeDecodesFromTheRealDefaultClientJSON() throws {
    let theme = try BundledDefaults.theme()

    #expect(theme.clientId == "default")
    #expect(theme.colors.light.primary == "#2563EB")
    #expect(theme.colors.dark.primary == "#3B82F6")
}
