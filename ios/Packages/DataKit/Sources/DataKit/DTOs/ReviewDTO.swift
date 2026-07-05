/// Decodes the contract's `Review`. `ReviewsRepositoryImpl` maps this onto
/// `DomainKit.Review`.
struct ReviewDTO: Decodable {
    let id: String
    let reviewerId: String
    let reviewerDisplayName: String?
    let revieweeId: String
    let listingId: String?
    let rating: Int
    let comment: String?
    let createdAt: String
}

/// What `POST /v1/reviews` accepts.
struct CreateReviewRequestDTO: Encodable {
    let revieweeId: String
    let listingId: String?
    let rating: Int
    let comment: String?
}
