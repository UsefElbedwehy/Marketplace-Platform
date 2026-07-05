/// Decodes the contract's `PublicSellerProfile`. `SellerProfileRepositoryImpl`
/// maps this onto `DomainKit.SellerProfile`.
struct SellerProfileDTO: Decodable {
    let id: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let memberSince: String
    let ratingCount: Int
    let ratingAverage: Double?
    let publishedListingCount: Int
}
