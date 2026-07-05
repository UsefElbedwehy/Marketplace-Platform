import Networking
@testable import Configuration

struct FakeAPIClient: APIClient {
    enum Behavior {
        case value(any Sendable)
        case notModified
        case throwing(Error)
    }

    var behavior: Behavior

    func send<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingTo type: T.Type) async throws -> APIResponse<T> {
        switch behavior {
        case .value(let v):
            return APIResponse(value: (v as! T), etag: "\"etag-1\"", notModified: false)
        case .notModified:
            return APIResponse(value: nil, etag: "\"etag-1\"", notModified: true)
        case .throwing(let error):
            throw error
        }
    }

    func sendCollection<T: Decodable & Sendable>(_ endpoint: APIEndpoint, decodingItemsTo type: T.Type) async throws -> (items: [T], page: PaginationMeta) {
        fatalError("not used by Configuration's tests")
    }

    func sendNoContent(_ endpoint: APIEndpoint) async throws {
        fatalError("not used by Configuration's tests")
    }
}

extension ConfigDTO {
    static func fixture(clientId: String = "default") -> ConfigDTO {
        ConfigDTO(
            schemaFormatVersion: "1.0.0",
            clientId: clientId,
            identity: .init(legalName: "Test Co", shortName: ["en": "Test"]),
            locales: .init(supported: ["en", "ar"], defaultLocale: "en", rtlLocales: ["ar"]),
            currencies: .init(supported: ["SAR", "USD"], defaultCurrency: "SAR"),
            countries: .init(supported: ["SA"], defaultCountry: "SA"),
            modules: .init(
                authentication: true, listings: true, search: true, favorites: true, chat: true,
                notifications: true, sellerDashboard: true, subscriptions: false, payments: false,
                wallet: false, advertisements: false, reviews: true, moderation: true
            ),
            featureFlags: [:],
            support: .init(email: "support@example.com", phone: nil, chatEnabled: true),
            legal: .init(termsUrl: "https://example.com/terms", privacyUrl: "https://example.com/privacy")
        )
    }
}

extension ThemeDTO {
    static func fixture(clientId: String = "default", themeVersion: Int = 1) -> ThemeDTO {
        let color = SemanticColorSet(
            primary: "#000000", secondary: "#000000", accent: "#000000", background: "#FFFFFF",
            surface: "#FFFFFF", card: "#FFFFFF", border: "#000000", textPrimary: "#000000",
            textSecondary: "#000000", placeholder: "#000000", success: "#000000", warning: "#000000",
            danger: "#000000", info: "#000000", separator: "#000000", overlay: "#000000",
            skeleton: "#000000", loading: "#000000", selection: "#000000", navigation: "#000000",
            toolbar: "#000000", tabBar: "#000000", glass: "#000000", material: "#000000",
            interactive: "#000000", badge: "#000000", favorite: "#000000", online: "#000000", offline: "#000000"
        )
        return ThemeDTO(
            schemaFormatVersion: "1.0.0",
            clientId: clientId,
            themeVersion: themeVersion,
            colors: .init(light: color, dark: color),
            typography: .init(fontFamily: "Inter", scale: [:]),
            shape: .init(cornerRadiusSmall: 4, cornerRadiusMedium: 8, cornerRadiusLarge: 16)
        )
    }
}

typealias SemanticColorSet = ThemeDTO.SemanticColorSet
