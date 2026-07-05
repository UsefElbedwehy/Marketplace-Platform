import Testing
@testable import Configuration
@testable import DataKit

@Test func configRepositoryMapsAllModuleFlags() {
    let dto = ConfigDTO(
        schemaFormatVersion: "1.0.0",
        clientId: "client_a",
        identity: .init(legalName: "Test", shortName: ["en": "Test"]),
        locales: .init(supported: ["en", "ar"], defaultLocale: "en", rtlLocales: ["ar"]),
        currencies: .init(supported: ["SAR", "USD"], defaultCurrency: "SAR"),
        countries: .init(supported: ["SA"], defaultCountry: "SA"),
        modules: .init(
            authentication: true, listings: true, search: false, favorites: true, chat: false,
            notifications: true, sellerDashboard: false, subscriptions: true, payments: false,
            wallet: true, advertisements: false, reviews: true, moderation: false
        ),
        featureFlags: ["dynamicFormsDebugPanel": true],
        support: .init(email: "support@example.com", phone: "+1", chatEnabled: false),
        legal: .init(termsUrl: "https://x/terms", privacyUrl: "https://x/privacy")
    )

    let config = ConfigRepositoryImpl.map(dto)

    #expect(config.clientId == "client_a")
    #expect(config.locales.supported.map(\.identifier) == ["en", "ar"])
    #expect(config.locales.defaultLocale.identifier == "en")
    #expect(config.modules.search == false)
    #expect(config.modules.wallet == true)
    #expect(config.featureFlags["dynamicFormsDebugPanel"] == true)
    #expect(config.support.chatEnabled == false)
}

@Test func configRepositoryMarksArabicAsRTL() {
    let dto = ConfigDTO(
        schemaFormatVersion: "1.0.0", clientId: "default",
        identity: .init(legalName: "Test", shortName: [:]),
        locales: .init(supported: ["ar"], defaultLocale: "ar", rtlLocales: ["ar"]),
        currencies: .init(supported: ["SAR"], defaultCurrency: "SAR"),
        countries: .init(supported: ["SA"], defaultCountry: "SA"),
        modules: .init(
            authentication: true, listings: true, search: true, favorites: true, chat: true,
            notifications: true, sellerDashboard: true, subscriptions: false, payments: false,
            wallet: false, advertisements: false, reviews: true, moderation: true
        ),
        featureFlags: [:],
        support: .init(email: "support@example.com", phone: nil, chatEnabled: true),
        legal: .init(termsUrl: "https://x/terms", privacyUrl: "https://x/privacy")
    )

    let config = ConfigRepositoryImpl.map(dto)

    #expect(config.locales.defaultLocale.isRTL == true)
}
