import Core
import DataKit
import DesignSystem
import DomainKit
import Networking
import Configuration
import SwiftData

// Container extensions for types only the App target itself ever touches
// directly (Networking/Configuration/DesignSystem concretes — Feature
// packages never depend on these per 01-system-architecture.md §4, so there's
// no cross-module visibility need; unlike the DomainKit-protocol overrides
// below, these can just be declared here).
extension Container {
    var tokenStore: Factory<TokenStore> {
        self { TokenStore() }.singleton
    }

    var apiClient: Factory<APIClient> {
        self {
            URLSessionAPIClient(baseURL: AppEnvironment.apiBaseURL, tokenStore: self.tokenStore())
        }.singleton
    }

    var configurationModelContainer: Factory<ModelContainer> {
        // A production on-disk cache — crashes if the SwiftData store can't be
        // created at all, which is the correct behavior for an unrecoverable
        // storage failure (ADR-0013: cache, but still a real persistent store).
        self { try! ModelContainer.configurationCache() }.singleton
    }

    var configurationLocalDataSource: Factory<ConfigurationLocalDataSource> {
        self { ConfigurationLocalDataSource(container: self.configurationModelContainer()) }.singleton
    }

    var configurationRemoteDataSource: Factory<ConfigurationRemoteDataSource> {
        self { ConfigurationRemoteDataSource(apiClient: self.apiClient()) }
    }

    var configurationDataSource: Factory<ConfigurationDataSource> {
        self {
            ConfigurationDataSource(local: self.configurationLocalDataSource(), remote: self.configurationRemoteDataSource())
        }.singleton
    }

    @MainActor
    var themeStore: Factory<ThemeStore> {
        self { @MainActor in ThemeStore(dataSource: self.configurationDataSource()) }.singleton
    }
}

/// Overrides every `DomainKit.DIRegistrationPoints` placeholder with its real
/// implementation (ADR-0012) — the concrete DataKit types are the only ones
/// this file needs to know about; everything else resolves the protocol via
/// `@Injected` and never sees this file. Called once at launch
/// (`MarketplacePlatformApp.init`).
func registerDependencies() {
    let container = Container.shared

    container.configRepository.register {
        ConfigRepositoryImpl(dataSource: container.configurationDataSource())
    }
    container.authRepository.register {
        AuthRepositoryImpl(apiClient: container.apiClient(), tokenStore: container.tokenStore(), tenantId: AppEnvironment.tenantId)
    }
    container.categoryRepository.register {
        CategoryRepositoryImpl(apiClient: container.apiClient())
    }
    container.listingRepository.register {
        ListingRepositoryImpl(apiClient: container.apiClient())
    }
    container.fetchBootstrapConfigUseCase.register {
        DefaultFetchBootstrapConfigUseCase(configRepository: container.configRepository())
    }
    container.authUseCase.register {
        DefaultAuthUseCase(authRepository: container.authRepository())
    }
    container.catalogUseCase.register {
        DefaultCatalogUseCase(categoryRepository: container.categoryRepository())
    }
    container.listingUseCase.register {
        DefaultListingUseCase(listingRepository: container.listingRepository())
    }
    container.chatRepository.register {
        ChatRepositoryImpl(apiClient: container.apiClient())
    }
    container.favoritesRepository.register {
        FavoritesRepositoryImpl(apiClient: container.apiClient())
    }
    container.reviewsRepository.register {
        ReviewsRepositoryImpl(apiClient: container.apiClient())
    }
    container.notificationsRepository.register {
        NotificationsRepositoryImpl(apiClient: container.apiClient())
    }
    container.sellerProfileRepository.register {
        SellerProfileRepositoryImpl(apiClient: container.apiClient())
    }
    container.chatUseCase.register {
        DefaultChatUseCase(chatRepository: container.chatRepository())
    }
    container.favoritesUseCase.register {
        DefaultFavoritesUseCase(favoritesRepository: container.favoritesRepository())
    }
    container.reviewsUseCase.register {
        DefaultReviewsUseCase(reviewsRepository: container.reviewsRepository())
    }
    container.notificationsUseCase.register {
        DefaultNotificationsUseCase(notificationsRepository: container.notificationsRepository())
    }
    container.sellerProfileUseCase.register {
        DefaultSellerProfileUseCase(sellerProfileRepository: container.sellerProfileRepository())
    }
}
