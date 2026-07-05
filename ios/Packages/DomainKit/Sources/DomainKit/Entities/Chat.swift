/// Buyer↔seller chat on a listing ⭐ (Phase 6 golden-path exit criterion).
/// Reads are poll-based (no Realtime — see `ChatRepository`'s doc comment).
public struct Conversation: Identifiable, Hashable, Sendable {
    public let id: String
    public let listingId: String
    public let listingTitle: String
    public let buyerId: String
    public let buyerDisplayName: String?
    public let sellerId: String
    public let sellerDisplayName: String?
    public let lastMessageAt: String?
    public let createdAt: String

    public init(
        id: String, listingId: String, listingTitle: String, buyerId: String, buyerDisplayName: String?,
        sellerId: String, sellerDisplayName: String?, lastMessageAt: String?, createdAt: String
    ) {
        self.id = id
        self.listingId = listingId
        self.listingTitle = listingTitle
        self.buyerId = buyerId
        self.buyerDisplayName = buyerDisplayName
        self.sellerId = sellerId
        self.sellerDisplayName = sellerDisplayName
        self.lastMessageAt = lastMessageAt
        self.createdAt = createdAt
    }

    /// The display name of whichever participant isn't `viewerId` — the
    /// server returns both names rather than picking one, since the row
    /// representation shouldn't depend on who's asking (see backend/src/
    /// chat_service.ts's header comment).
    public func otherParticipantDisplayName(viewerId: String) -> String? {
        viewerId == buyerId ? sellerDisplayName : buyerDisplayName
    }
}

public struct Message: Identifiable, Hashable, Sendable {
    public let id: String
    public let conversationId: String
    public let senderId: String
    public let body: String
    public let readAt: String?
    public let createdAt: String

    public init(id: String, conversationId: String, senderId: String, body: String, readAt: String?, createdAt: String) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.body = body
        self.readAt = readAt
        self.createdAt = createdAt
    }
}
