import Core

/// Container extension *declarations* for every protocol resolved via
/// `@Injected` outside the App target — DomainKit is the one package visible
/// from everywhere (Core, DataKit, DynamicForms, every `Features/*` module),
/// so this is where the KeyPath has to live for e.g.
/// `@Injected(\.catalogUseCase)` to even compile in a Feature package.
///
/// These closures are placeholders that fail loudly if ever actually
/// resolved — the composition root (`ios/App/Sources/App/Composition`)
/// overrides every one of them via Factory's `.register(factory:)` at
/// launch (its documented mechanism for exactly this: declare a Factory in
/// one module, supply its real implementation from another). If one of these
/// `fatalError`s fires, the App forgot to register that dependency.
extension Container {
    public var configRepository: Factory<ConfigRepository> {
        self { fatalError("ConfigRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var authRepository: Factory<AuthRepository> {
        self { fatalError("AuthRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var categoryRepository: Factory<CategoryRepository> {
        self { fatalError("CategoryRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var listingRepository: Factory<ListingRepository> {
        self { fatalError("ListingRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var fetchBootstrapConfigUseCase: Factory<FetchBootstrapConfigUseCase> {
        self { fatalError("FetchBootstrapConfigUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var authUseCase: Factory<AuthUseCase> {
        self { fatalError("AuthUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var catalogUseCase: Factory<CatalogUseCase> {
        self { fatalError("CatalogUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var listingUseCase: Factory<ListingUseCase> {
        self { fatalError("ListingUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var chatRepository: Factory<ChatRepository> {
        self { fatalError("ChatRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var favoritesRepository: Factory<FavoritesRepository> {
        self { fatalError("FavoritesRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var reviewsRepository: Factory<ReviewsRepository> {
        self { fatalError("ReviewsRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var notificationsRepository: Factory<NotificationsRepository> {
        self { fatalError("NotificationsRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var sellerProfileRepository: Factory<SellerProfileRepository> {
        self { fatalError("SellerProfileRepository not registered — see ios/App/Sources/App/Composition") }
    }

    public var chatUseCase: Factory<ChatUseCase> {
        self { fatalError("ChatUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var favoritesUseCase: Factory<FavoritesUseCase> {
        self { fatalError("FavoritesUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var reviewsUseCase: Factory<ReviewsUseCase> {
        self { fatalError("ReviewsUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var notificationsUseCase: Factory<NotificationsUseCase> {
        self { fatalError("NotificationsUseCase not registered — see ios/App/Sources/App/Composition") }
    }

    public var sellerProfileUseCase: Factory<SellerProfileUseCase> {
        self { fatalError("SellerProfileUseCase not registered — see ios/App/Sources/App/Composition") }
    }
}
