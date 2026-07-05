/// Decodes the contract's `Favorite`. `FavoritesRepositoryImpl` maps this
/// onto `DomainKit.Favorite`.
struct FavoriteDTO: Decodable {
    let id: String
    let listingId: String
    let createdAt: String
}
