import Testing
import Core
import Networking
@testable import DataKit
@testable import DomainKit

@Test func reviewsRepositoryCreatesAReview() async throws {
    let dto = ReviewDTO(id: "r1", reviewerId: "buyer-1", reviewerDisplayName: "Dev Buyer", revieweeId: "seller-1", listingId: "l1", rating: 5, comment: "Great!", createdAt: "2026-01-01T00:00:00Z")
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/reviews", value: dto)])
    let repo = ReviewsRepositoryImpl(apiClient: client)

    let review = try await repo.createReview(CreateReviewDraft(revieweeId: "seller-1", listingId: "l1", rating: 5, comment: "Great!"))

    #expect(review.rating == 5)
    #expect(review.reviewerDisplayName == "Dev Buyer")
}

@Test func reviewsRepositoryFetchesReviewsForASellerWithoutRequiringAuth() async throws {
    let dto = ReviewDTO(id: "r1", reviewerId: "buyer-1", reviewerDisplayName: "Dev Buyer", revieweeId: "seller-1", listingId: nil, rating: 4, comment: nil, createdAt: "2026-01-01T00:00:00Z")
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/reviews", value: [dto])])
    let repo = ReviewsRepositoryImpl(apiClient: client)

    let reviews = try await repo.fetchReviews(sellerId: "seller-1")

    #expect(reviews.count == 1)
    #expect(client.lastRequiredAuth == false)
}

@Test func reviewsRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/reviews", value: nil, error: Boom())])
    let repo = ReviewsRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.fetchReviews(sellerId: "seller-1")
    }
}
