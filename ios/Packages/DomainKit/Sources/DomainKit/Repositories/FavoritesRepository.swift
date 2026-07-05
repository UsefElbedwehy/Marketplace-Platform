public protocol FavoritesRepository: Sendable {
    func fetchFavorites() async throws -> [Favorite]
    /// Idempotent — favoriting an already-favorited listing is a no-op
    /// returning the same favorite, not an error.
    func addFavorite(listingId: String) async throws -> Favorite
    /// Idempotent — unfavoriting a listing that isn't favorited is a
    /// harmless no-op.
    func removeFavorite(listingId: String) async throws
}
