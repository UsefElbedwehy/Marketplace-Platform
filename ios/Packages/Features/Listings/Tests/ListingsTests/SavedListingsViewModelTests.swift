import Testing
import DomainKit
@testable import Listings

@Suite @MainActor struct SavedListingsViewModelTests {
    @Test func loadFetchesTheFavoritedListingsThemselves() async {
        let viewModel = SavedListingsViewModel(
            favoritesUseCase: StubFavoritesUseCase(favorites: [.fixture(listingId: "l1")]),
            listingUseCase: StubListingUseCase(listing: .fixture(id: "l1"))
        )

        await viewModel.load()

        #expect(viewModel.listings.map(\.id) == ["l1"])
    }

    @Test func removeFavoriteDropsTheListingFromTheList() async {
        let viewModel = SavedListingsViewModel(
            favoritesUseCase: StubFavoritesUseCase(favorites: [.fixture(listingId: "l1")]),
            listingUseCase: StubListingUseCase(listing: .fixture(id: "l1"))
        )
        await viewModel.load()

        await viewModel.removeFavorite(listingId: "l1")

        #expect(viewModel.listings.isEmpty)
    }

    @Test func loadSurfacesAnErrorMessage() async {
        struct Boom: Error {}
        let viewModel = SavedListingsViewModel(favoritesUseCase: StubFavoritesUseCase(error: Boom()), listingUseCase: StubListingUseCase())

        await viewModel.load()

        #expect(viewModel.errorMessage != nil)
    }
}
