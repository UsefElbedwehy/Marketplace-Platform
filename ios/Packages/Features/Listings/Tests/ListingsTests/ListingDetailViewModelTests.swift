import Testing
import DomainKit
@testable import Listings

@Suite @MainActor struct ListingDetailViewModelTests {
    @Test func loadFetchesTheListingAndItsCategorySchema() async {
        let listing = Listing.fixture(id: "l1")
        let viewModel = ListingDetailViewModel(
            listingUseCase: StubListingUseCase(listing: listing),
            catalogUseCase: StubCatalogUseCase(schema: .fixture(schemaVersion: 4)),
            favoritesUseCase: StubFavoritesUseCase(),
            chatUseCase: StubChatUseCaseForListings()
        )

        await viewModel.load(listingId: "l1")

        #expect(viewModel.listing?.id == "l1")
        #expect(viewModel.schema?.schemaVersion == 4)
    }

    @Test func attributeRowsProjectTheAttributesIndexAgainstTheSchemaLabels() async {
        let listing = Listing(
            id: "l1", ownerId: "seller-1", categoryId: "cat-1", title: "2019 BMW", description: nil, price: 85000, currency: "SAR",
            status: .published, attributesIndex: ["brand": .string("bmw")], createdAt: "2026-01-01T00:00:00Z"
        )
        let viewModel = ListingDetailViewModel(
            listingUseCase: StubListingUseCase(listing: listing), catalogUseCase: StubCatalogUseCase(schema: .fixture()),
            favoritesUseCase: StubFavoritesUseCase(), chatUseCase: StubChatUseCaseForListings()
        )

        await viewModel.load(listingId: "l1")

        #expect(viewModel.attributeRows.count == 1)
        #expect(viewModel.attributeRows.first?.label == "Brand")
        #expect(viewModel.attributeRows.first?.value == "bmw")
    }

    @Test func attributeRowsSkipKeysNotPresentOnTheListing() async {
        // The fixture schema declares "brand" but the listing has no value
        // for it — the row should be omitted, not shown blank.
        let listing = Listing(
            id: "l1", ownerId: "seller-1", categoryId: "cat-1", title: "t", description: nil, price: nil, currency: nil,
            status: .draft, attributesIndex: [:], createdAt: "2026-01-01T00:00:00Z"
        )
        let viewModel = ListingDetailViewModel(
            listingUseCase: StubListingUseCase(listing: listing), catalogUseCase: StubCatalogUseCase(schema: .fixture()),
            favoritesUseCase: StubFavoritesUseCase(), chatUseCase: StubChatUseCaseForListings()
        )

        await viewModel.load(listingId: "l1")

        #expect(viewModel.attributeRows.isEmpty)
    }
}
