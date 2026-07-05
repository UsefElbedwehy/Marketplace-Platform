import Configuration
import Core
import DomainKit

/// Fulfils `DomainKit.ConfigRepository` by wrapping `Configuration`'s
/// cache-then-network data source and mapping its DTO onto `AppConfiguration`
/// — the only place a `ConfigDTO` is translated into the domain shape.
public struct ConfigRepositoryImpl: ConfigRepository {
    private let dataSource: ConfigurationDataSource

    public init(dataSource: ConfigurationDataSource) {
        self.dataSource = dataSource
    }

    public func fetchConfiguration() async throws -> AppConfiguration {
        do {
            let dto = try await dataSource.loadConfig()
            return Self.map(dto)
        } catch {
            throw DomainError.unknown(message: "Failed to load configuration: \(error)")
        }
    }

    static func map(_ dto: ConfigDTO) -> AppConfiguration {
        AppConfiguration(
            schemaVersion: dto.schemaFormatVersion,
            clientId: dto.clientId,
            locales: .init(
                supported: dto.locales.supported.map(AppLocale.init(identifier:)),
                defaultLocale: AppLocale(identifier: dto.locales.defaultLocale)
            ),
            currencies: dto.currencies.supported,
            defaultCurrency: dto.currencies.defaultCurrency,
            modules: .init(
                authentication: dto.modules.authentication,
                listings: dto.modules.listings,
                search: dto.modules.search,
                favorites: dto.modules.favorites,
                chat: dto.modules.chat,
                notifications: dto.modules.notifications,
                sellerDashboard: dto.modules.sellerDashboard,
                subscriptions: dto.modules.subscriptions,
                payments: dto.modules.payments,
                wallet: dto.modules.wallet,
                advertisements: dto.modules.advertisements,
                reviews: dto.modules.reviews,
                moderation: dto.modules.moderation
            ),
            featureFlags: dto.featureFlags,
            support: .init(email: dto.support.email, phone: dto.support.phone, chatEnabled: dto.support.chatEnabled)
        )
    }
}
