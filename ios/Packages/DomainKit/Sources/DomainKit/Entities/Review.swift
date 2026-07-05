/// A buyer's rating of a seller — immutable once posted (no update/delete
/// path; social.review has no such RLS policy). Aggregated onto the
/// seller's `SellerProfile` by a database trigger, not client math.
public struct Review: Identifiable, Equatable, Sendable {
    public let id: String
    public let reviewerId: String
    public let reviewerDisplayName: String?
    public let revieweeId: String
    public let listingId: String?
    public let rating: Int
    public let comment: String?
    public let createdAt: String

    public init(
        id: String, reviewerId: String, reviewerDisplayName: String?, revieweeId: String,
        listingId: String?, rating: Int, comment: String?, createdAt: String
    ) {
        self.id = id
        self.reviewerId = reviewerId
        self.reviewerDisplayName = reviewerDisplayName
        self.revieweeId = revieweeId
        self.listingId = listingId
        self.rating = rating
        self.comment = comment
        self.createdAt = createdAt
    }
}

/// What the "rate a seller" form submits — mirrors `CreateReviewRequest`.
public struct CreateReviewDraft: Equatable, Sendable {
    public let revieweeId: String
    public let listingId: String?
    public let rating: Int
    public let comment: String?

    public init(revieweeId: String, listingId: String?, rating: Int, comment: String?) {
        self.revieweeId = revieweeId
        self.listingId = listingId
        self.rating = rating
        self.comment = comment
    }
}
