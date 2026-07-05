/// Mirrors `configs/clients/<id>/config.json` (docs/planning/
/// 07-configuration-whitelabel-theme.md) field-for-field — this is the
/// *build/runtime-config* DTO, not a trimmed domain projection (that's
/// `DomainKit.AppConfiguration`, produced from this by `DataKit`).
public struct ConfigDTO: Codable, Equatable, Sendable {
    public struct Identity: Codable, Equatable, Sendable {
        public let legalName: String
        public let shortName: [String: String]
    }
    public struct Locales: Codable, Equatable, Sendable {
        public let supported: [String]
        public let defaultLocale: String
        public let rtlLocales: [String]

        enum CodingKeys: String, CodingKey {
            case supported, rtlLocales
            case defaultLocale = "default"
        }
    }
    public struct Currencies: Codable, Equatable, Sendable {
        public let supported: [String]
        public let defaultCurrency: String

        enum CodingKeys: String, CodingKey {
            case supported
            case defaultCurrency = "default"
        }
    }
    public struct Countries: Codable, Equatable, Sendable {
        public let supported: [String]
        public let defaultCountry: String

        enum CodingKeys: String, CodingKey {
            case supported
            case defaultCountry = "default"
        }
    }
    public struct Modules: Codable, Equatable, Sendable {
        public let authentication: Bool
        public let listings: Bool
        public let search: Bool
        public let favorites: Bool
        public let chat: Bool
        public let notifications: Bool
        public let sellerDashboard: Bool
        public let subscriptions: Bool
        public let payments: Bool
        public let wallet: Bool
        public let advertisements: Bool
        public let reviews: Bool
        public let moderation: Bool
    }
    public struct Support: Codable, Equatable, Sendable {
        public let email: String
        public let phone: String?
        public let chatEnabled: Bool
    }
    public struct Legal: Codable, Equatable, Sendable {
        public let termsUrl: String
        public let privacyUrl: String
    }

    public let schemaFormatVersion: String
    public let clientId: String
    public let identity: Identity
    public let locales: Locales
    public let currencies: Currencies
    public let countries: Countries
    public let modules: Modules
    public let featureFlags: [String: Bool]
    public let support: Support
    public let legal: Legal

    public init(
        schemaFormatVersion: String, clientId: String, identity: Identity, locales: Locales,
        currencies: Currencies, countries: Countries, modules: Modules, featureFlags: [String: Bool],
        support: Support, legal: Legal
    ) {
        self.schemaFormatVersion = schemaFormatVersion
        self.clientId = clientId
        self.identity = identity
        self.locales = locales
        self.currencies = currencies
        self.countries = countries
        self.modules = modules
        self.featureFlags = featureFlags
        self.support = support
        self.legal = legal
    }
}
