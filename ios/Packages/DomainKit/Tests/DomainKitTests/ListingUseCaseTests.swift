import Testing
@testable import DomainKit

@Test func listingUseCaseCreatesAndReturnsTheListing() async throws {
    let repo = StubListingRepository(listing: .fixture(id: "new-1"))
    let useCase = DefaultListingUseCase(listingRepository: repo)
    let draft = CreateListingDraft(categoryId: "cat-1", title: "2019 BMW", description: nil, price: 85000, currency: "SAR", attributes: ["brand": .string("bmw")])

    let listing = try await useCase.createListing(draft)

    #expect(listing.id == "new-1")
    let capturedDraft = await repo.created
    #expect(capturedDraft == draft)
}

@Test func listingUseCaseFetchesASingleListing() async throws {
    let useCase = DefaultListingUseCase(listingRepository: StubListingRepository(listing: .fixture(id: "l-42")))

    let listing = try await useCase.fetchListing(id: "l-42")

    #expect(listing.id == "l-42")
}

@Test func listingUseCaseFetchesAFilteredPage() async throws {
    let page = Page<Listing>(items: [.fixture(status: .published)], nextCursor: "cursor-1", hasMore: true)
    let useCase = DefaultListingUseCase(listingRepository: StubListingRepository(page: page))

    let result = try await useCase.fetchListings(filters: ListingFilters(categoryId: "cat-1"))

    #expect(result.items.first?.status == .published)
    #expect(result.hasMore == true)
}

@Test func listingUseCaseUpdatesStatus() async throws {
    let useCase = DefaultListingUseCase(listingRepository: StubListingRepository(listing: .fixture(status: .pendingReview)))

    let listing = try await useCase.updateStatus(listingId: "l-1", status: .published)

    #expect(listing.status == .published)
}

@Test func listingUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultListingUseCase(listingRepository: StubListingRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchListing(id: "l-1")
    }
}

@Test func attributeValueDisplayStringsAreHumanReadable() {
    #expect(AttributeValue.string("bmw").displayString == "bmw")
    #expect(AttributeValue.number(84000).displayString == "84000")
    #expect(AttributeValue.number(2.5).displayString == "2.5")
    #expect(AttributeValue.bool(true).displayString == "Yes")
    #expect(AttributeValue.bool(false).displayString == "No")
    #expect(AttributeValue.stringArray(["a", "b"]).displayString == "a, b")
    #expect(AttributeValue.null.displayString == "")
}
