public protocol ReviewsUseCase: Sendable {
    func fetchReviews(sellerId: String) async throws -> [Review]
    func createReview(_ draft: CreateReviewDraft) async throws -> Review
}

public struct DefaultReviewsUseCase: ReviewsUseCase {
    private let reviewsRepository: ReviewsRepository

    public init(reviewsRepository: ReviewsRepository) {
        self.reviewsRepository = reviewsRepository
    }

    public func fetchReviews(sellerId: String) async throws -> [Review] {
        try await reviewsRepository.fetchReviews(sellerId: sellerId)
    }

    public func createReview(_ draft: CreateReviewDraft) async throws -> Review {
        try await reviewsRepository.createReview(draft)
    }
}
