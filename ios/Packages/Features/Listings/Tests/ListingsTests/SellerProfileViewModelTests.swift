import Testing
import DomainKit
@testable import Listings

@Suite @MainActor struct SellerProfileViewModelTests {
    @Test func loadFetchesTheProfileAndItsReviews() async {
        let viewModel = SellerProfileViewModel(
            sellerProfileUseCase: StubSellerProfileUseCase(profile: .fixture(ratingCount: 3, ratingAverage: 4.7)),
            reviewsUseCase: StubReviewsUseCase(reviews: [.fixture()])
        )

        await viewModel.load(sellerId: "seller-1")

        #expect(viewModel.profile?.ratingCount == 3)
        #expect(viewModel.reviews.count == 1)
    }

    @Test func submitReviewCreatesItAndRefreshesTheAggregate() async {
        let viewModel = SellerProfileViewModel(
            sellerProfileUseCase: StubSellerProfileUseCase(profile: .fixture(ratingCount: 4, ratingAverage: 4.5)),
            reviewsUseCase: StubReviewsUseCase(reviews: [.fixture(), .fixture(id: "r2", rating: 4)])
        )

        await viewModel.submitReview(sellerId: "seller-1", rating: 4, comment: "Nice")

        #expect(viewModel.reviewSubmitted)
        #expect(viewModel.reviews.count == 2)
        #expect(viewModel.profile?.ratingCount == 4)
    }

    @Test func loadSurfacesAnErrorMessage() async {
        struct Boom: Error {}
        let viewModel = SellerProfileViewModel(sellerProfileUseCase: StubSellerProfileUseCase(error: Boom()), reviewsUseCase: StubReviewsUseCase())

        await viewModel.load(sellerId: "seller-1")

        #expect(viewModel.errorMessage != nil)
    }
}
