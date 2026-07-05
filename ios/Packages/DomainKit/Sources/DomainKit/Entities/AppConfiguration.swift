import Core

/// The domain projection of a client's Development Schema `config.json`
/// (docs/planning/07-configuration-whitelabel-theme.md) — only the fields the
/// app boot sequence and module gating actually need, not a 1:1 mirror of
/// every dashboard-editable field (that full shape lives in `Configuration`'s
/// DTO and stays there).
public struct AppConfiguration: Equatable, Sendable {
    public struct Locales: Equatable, Sendable {
        public let supported: [AppLocale]
        public let defaultLocale: AppLocale

        public init(supported: [AppLocale], defaultLocale: AppLocale) {
            self.supported = supported
            self.defaultLocale = defaultLocale
        }
    }

    public struct Modules: Equatable, Sendable {
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

        public init(
            authentication: Bool, listings: Bool, search: Bool, favorites: Bool, chat: Bool,
            notifications: Bool, sellerDashboard: Bool, subscriptions: Bool, payments: Bool,
            wallet: Bool, advertisements: Bool, reviews: Bool, moderation: Bool
        ) {
            self.authentication = authentication
            self.listings = listings
            self.search = search
            self.favorites = favorites
            self.chat = chat
            self.notifications = notifications
            self.sellerDashboard = sellerDashboard
            self.subscriptions = subscriptions
            self.payments = payments
            self.wallet = wallet
            self.advertisements = advertisements
            self.reviews = reviews
            self.moderation = moderation
        }
    }

    public struct Support: Equatable, Sendable {
        public let email: String
        public let phone: String?
        public let chatEnabled: Bool

        public init(email: String, phone: String?, chatEnabled: Bool) {
            self.email = email
            self.phone = phone
            self.chatEnabled = chatEnabled
        }
    }

    public let schemaVersion: String
    public let clientId: String
    public let locales: Locales
    public let currencies: [String]
    public let defaultCurrency: String
    public let modules: Modules
    public let featureFlags: [String: Bool]
    public let support: Support

    public init(
        schemaVersion: String, clientId: String, locales: Locales, currencies: [String],
        defaultCurrency: String, modules: Modules, featureFlags: [String: Bool], support: Support
    ) {
        self.schemaVersion = schemaVersion
        self.clientId = clientId
        self.locales = locales
        self.currencies = currencies
        self.defaultCurrency = defaultCurrency
        self.modules = modules
        self.featureFlags = featureFlags
        self.support = support
    }
}
