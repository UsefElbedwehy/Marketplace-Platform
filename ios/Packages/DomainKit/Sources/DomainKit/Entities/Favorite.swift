/// A buyer's saved listing — owner-only (docs/planning/04-database-
/// architecture.md §4).
public struct Favorite: Identifiable, Equatable, Sendable {
    public let id: String
    public let listingId: String
    public let createdAt: String

    public init(id: String, listingId: String, createdAt: String) {
        self.id = id
        self.listingId = listingId
        self.createdAt = createdAt
    }
}
