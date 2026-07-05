@testable import DomainKit

struct StubChatRepository: ChatRepository {
    var conversations: [Conversation] = []
    var conversation: Conversation = .fixture()
    var messages: [Message] = []
    var message: Message = .fixture()
    var error: Error?

    func fetchConversations() async throws -> [Conversation] {
        if let error { throw error }
        return conversations
    }

    func startConversation(listingId: String) async throws -> Conversation {
        if let error { throw error }
        return conversation
    }

    func fetchMessages(conversationId: String) async throws -> [Message] {
        if let error { throw error }
        return messages
    }

    func sendMessage(conversationId: String, body: String) async throws -> Message {
        if let error { throw error }
        return message
    }
}

struct StubFavoritesRepository: FavoritesRepository {
    var favorites: [Favorite] = []
    var favorite: Favorite = .fixture()
    var error: Error?
    var removedListingId: String?

    func fetchFavorites() async throws -> [Favorite] {
        if let error { throw error }
        return favorites
    }

    func addFavorite(listingId: String) async throws -> Favorite {
        if let error { throw error }
        return favorite
    }

    func removeFavorite(listingId: String) async throws {
        if let error { throw error }
    }
}

struct StubReviewsRepository: ReviewsRepository {
    var reviews: [Review] = []
    var review: Review = .fixture()
    var error: Error?

    func fetchReviews(sellerId: String) async throws -> [Review] {
        if let error { throw error }
        return reviews
    }

    func createReview(_ draft: CreateReviewDraft) async throws -> Review {
        if let error { throw error }
        return review
    }
}

struct StubNotificationsRepository: NotificationsRepository {
    var notifications: [AppNotification] = []
    var notification: AppNotification = .fixture()
    var error: Error?

    func fetchNotifications() async throws -> [AppNotification] {
        if let error { throw error }
        return notifications
    }

    func markRead(id: String) async throws -> AppNotification {
        if let error { throw error }
        return notification
    }
}

struct StubSellerProfileRepository: SellerProfileRepository {
    var profile: SellerProfile = .fixture()
    var error: Error?

    func fetchSellerProfile(id: String) async throws -> SellerProfile {
        if let error { throw error }
        return profile
    }
}

extension Conversation {
    static func fixture(id: String = "c1") -> Conversation {
        Conversation(
            id: id, listingId: "l1", listingTitle: "2019 BMW", buyerId: "buyer-1", buyerDisplayName: "Dev Buyer",
            sellerId: "seller-1", sellerDisplayName: "Dev Seller", lastMessageAt: nil, createdAt: "2026-01-01T00:00:00Z"
        )
    }
}

extension Message {
    static func fixture(id: String = "m1", body: String = "hi") -> Message {
        Message(id: id, conversationId: "c1", senderId: "buyer-1", body: body, readAt: nil, createdAt: "2026-01-01T00:00:00Z")
    }
}

extension Favorite {
    static func fixture(id: String = "f1", listingId: String = "l1") -> Favorite {
        Favorite(id: id, listingId: listingId, createdAt: "2026-01-01T00:00:00Z")
    }
}

extension Review {
    static func fixture(id: String = "r1", rating: Int = 5) -> Review {
        Review(id: id, reviewerId: "buyer-1", reviewerDisplayName: "Dev Buyer", revieweeId: "seller-1", listingId: "l1", rating: rating, comment: "Great!", createdAt: "2026-01-01T00:00:00Z")
    }
}

extension AppNotification {
    static func fixture(id: String = "n1", type: AppNotificationType = .chatMessage) -> AppNotification {
        AppNotification(id: id, type: type, payload: ["conversationId": .string("c1")], readAt: nil, deliveredAt: nil, createdAt: "2026-01-01T00:00:00Z")
    }
}

extension SellerProfile {
    static func fixture(id: String = "seller-1", ratingCount: Int = 3, ratingAverage: Double? = 4.7) -> SellerProfile {
        SellerProfile(id: id, displayName: "Dev Seller", avatarUrl: nil, bio: nil, memberSince: "2026-01-01T00:00:00Z", ratingCount: ratingCount, ratingAverage: ratingAverage, publishedListingCount: 5)
    }
}
