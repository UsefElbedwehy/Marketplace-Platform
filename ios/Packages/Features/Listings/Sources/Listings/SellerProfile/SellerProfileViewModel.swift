import Core
import DomainKit
import Observation

@Observable
@MainActor
final class SellerProfileViewModel {
    private(set) var profile: SellerProfile?
    private(set) var reviews: [Review] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isSubmittingReview = false
    private(set) var reviewSubmitted = false

    private let sellerProfileUseCase: SellerProfileUseCase
    private let reviewsUseCase: ReviewsUseCase

    init(
        sellerProfileUseCase: SellerProfileUseCase = Container.shared.sellerProfileUseCase(),
        reviewsUseCase: ReviewsUseCase = Container.shared.reviewsUseCase()
    ) {
        self.sellerProfileUseCase = sellerProfileUseCase
        self.reviewsUseCase = reviewsUseCase
    }

    // Their individual listings aren't enumerated here — `profile.
    // publishedListingCount` already carries that signal, and browsing a
    // seller's listings generically is what Search/Home already do; this
    // view stays focused on the trust signals (rating, reviews) a public
    // profile is for.
    func load(sellerId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let profileTask = sellerProfileUseCase.fetchSellerProfile(id: sellerId)
            async let reviewsTask = reviewsUseCase.fetchReviews(sellerId: sellerId)
            let (profile, reviews) = try await (profileTask, reviewsTask)
            self.profile = profile
            self.reviews = reviews
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func submitReview(sellerId: String, rating: Int, comment: String?) async {
        isSubmittingReview = true
        errorMessage = nil
        defer { isSubmittingReview = false }
        do {
            _ = try await reviewsUseCase.createReview(CreateReviewDraft(revieweeId: sellerId, listingId: nil, rating: rating, comment: comment))
            reviewSubmitted = true
            await load(sellerId: sellerId)
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }
}
