import Testing
@testable import DomainKit

// Chat

@Test func chatUseCaseFetchesConversations() async throws {
    let useCase = DefaultChatUseCase(chatRepository: StubChatRepository(conversations: [.fixture()]))

    let conversations = try await useCase.fetchConversations()

    #expect(conversations == [.fixture()])
}

@Test func chatUseCaseSendsAMessage() async throws {
    let useCase = DefaultChatUseCase(chatRepository: StubChatRepository(message: .fixture(body: "hello")))

    let message = try await useCase.sendMessage(conversationId: "c1", body: "hello")

    #expect(message.body == "hello")
}

@Test func chatUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultChatUseCase(chatRepository: StubChatRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchConversations()
    }
}

// Favorites

@Test func favoritesUseCaseAddsAndRemovesAFavorite() async throws {
    let useCase = DefaultFavoritesUseCase(favoritesRepository: StubFavoritesRepository(favorite: .fixture(listingId: "l9")))

    let favorite = try await useCase.addFavorite(listingId: "l9")
    try await useCase.removeFavorite(listingId: "l9")

    #expect(favorite.listingId == "l9")
}

@Test func favoritesUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultFavoritesUseCase(favoritesRepository: StubFavoritesRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchFavorites()
    }
}

// Reviews

@Test func reviewsUseCaseCreatesAReview() async throws {
    let useCase = DefaultReviewsUseCase(reviewsRepository: StubReviewsRepository(review: .fixture(rating: 5)))

    let review = try await useCase.createReview(CreateReviewDraft(revieweeId: "seller-1", listingId: "l1", rating: 5, comment: "Great!"))

    #expect(review.rating == 5)
}

@Test func reviewsUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultReviewsUseCase(reviewsRepository: StubReviewsRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchReviews(sellerId: "seller-1")
    }
}

// Notifications

@Test func notificationsUseCaseMarksRead() async throws {
    let notification = AppNotification(id: "n1", type: .chatMessage, payload: [:], readAt: "2026-01-01T00:01:00Z", deliveredAt: nil, createdAt: "2026-01-01T00:00:00Z")
    let useCase = DefaultNotificationsUseCase(notificationsRepository: StubNotificationsRepository(notification: notification))

    let result = try await useCase.markRead(id: "n1")

    #expect(result.readAt == "2026-01-01T00:01:00Z")
}

@Test func notificationsUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultNotificationsUseCase(notificationsRepository: StubNotificationsRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchNotifications()
    }
}

// Seller profile

@Test func sellerProfileUseCaseFetchesAProfile() async throws {
    let useCase = DefaultSellerProfileUseCase(sellerProfileRepository: StubSellerProfileRepository(profile: .fixture(ratingCount: 10, ratingAverage: 4.2)))

    let profile = try await useCase.fetchSellerProfile(id: "seller-1")

    #expect(profile.ratingCount == 10)
    #expect(profile.ratingAverage == 4.2)
}

@Test func sellerProfileUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultSellerProfileUseCase(sellerProfileRepository: StubSellerProfileRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchSellerProfile(id: "seller-1")
    }
}
