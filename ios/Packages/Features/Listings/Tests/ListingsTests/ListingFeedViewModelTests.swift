import Testing
import DomainKit
@testable import Listings

@Suite @MainActor struct ListingFeedViewModelTests {
    @Test func loadFirstPagePopulatesListingsAndPaginationState() async {
        let page = Page<Listing>(items: [.fixture(status: .published)], nextCursor: "cursor-1", hasMore: true)
        let viewModel = ListingFeedViewModel(listingUseCase: StubListingUseCase(page: page))

        await viewModel.loadFirstPage()

        #expect(viewModel.listings.count == 1)
        #expect(viewModel.hasMore == true)
    }

    @Test func loadFirstPageResetsAnyPreviouslyLoadedListings() async {
        let firstPage = Page<Listing>(items: [.fixture(id: "l1"), .fixture(id: "l2")], nextCursor: nil, hasMore: false)
        let viewModel = ListingFeedViewModel(listingUseCase: StubListingUseCase(page: firstPage))
        await viewModel.loadFirstPage()
        #expect(viewModel.listings.count == 2)

        let emptyPage = Page<Listing>(items: [], nextCursor: nil, hasMore: false)
        let secondUseCase = StubListingUseCase(page: emptyPage)
        let viewModel2 = ListingFeedViewModel(listingUseCase: secondUseCase)
        await viewModel2.loadFirstPage()

        #expect(viewModel2.listings.isEmpty)
    }

    @Test func loadSurfacesAnErrorMessage() async {
        struct Boom: Error {}
        let viewModel = ListingFeedViewModel(listingUseCase: StubListingUseCase(fetchListingsError: Boom()))

        await viewModel.loadFirstPage()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.listings.isEmpty)
    }
}
