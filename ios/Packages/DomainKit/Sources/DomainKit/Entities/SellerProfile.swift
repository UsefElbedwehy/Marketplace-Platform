/// A seller's PUBLIC profile ⭐ (Phase 6 golden-path exit criterion: "view a
/// seller profile") — distinct from the admin-only `UserProfile` (Phase 5's
/// user/role management). `ratingAverage` is computed server-side from
/// `ratingCount`/a running sum, never stored as a float to avoid drift.
public struct SellerProfile: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayName: String?
    public let avatarUrl: String?
    public let bio: String?
    public let memberSince: String
    public let ratingCount: Int
    public let ratingAverage: Double?
    public let publishedListingCount: Int

    public init(
        id: String, displayName: String?, avatarUrl: String?, bio: String?, memberSince: String,
        ratingCount: Int, ratingAverage: Double?, publishedListingCount: Int
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.bio = bio
        self.memberSince = memberSince
        self.ratingCount = ratingCount
        self.ratingAverage = ratingAverage
        self.publishedListingCount = publishedListingCount
    }
}
