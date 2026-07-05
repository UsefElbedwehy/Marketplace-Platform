public protocol ReviewsRepository: Sendable {
    func fetchReviews(sellerId: String) async throws -> [Review]
    func createReview(_ draft: CreateReviewDraft) async throws -> Review
}
