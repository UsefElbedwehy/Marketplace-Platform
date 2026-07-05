public protocol FavoritesUseCase: Sendable {
    func fetchFavorites() async throws -> [Favorite]
    func addFavorite(listingId: String) async throws -> Favorite
    func removeFavorite(listingId: String) async throws
}

public struct DefaultFavoritesUseCase: FavoritesUseCase {
    private let favoritesRepository: FavoritesRepository

    public init(favoritesRepository: FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    public func fetchFavorites() async throws -> [Favorite] {
        try await favoritesRepository.fetchFavorites()
    }

    public func addFavorite(listingId: String) async throws -> Favorite {
        try await favoritesRepository.addFavorite(listingId: listingId)
    }

    public func removeFavorite(listingId: String) async throws {
        try await favoritesRepository.removeFavorite(listingId: listingId)
    }
}
