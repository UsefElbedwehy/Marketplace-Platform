import Testing
import Core
import Foundation
import Networking
@testable import DataKit
@testable import DomainKit

func makeListingDTO(id: String = "l1", status: String = "draft") -> ListingDTO {
    ListingDTO(
        id: id, ownerId: "seller-1", categoryId: "cat-1", title: "2019 BMW", description: nil, price: 85000, currency: "SAR",
        status: status, attributesIndex: ["brand": .string("bmw"), "mileage": .number(84000), "featured": .bool(true)],
        createdAt: "2026-01-01T00:00:00Z"
    )
}

@Test func listingRepositoryCreateListingEncodesTheDraftAndMapsTheResponse() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/listings", value: makeListingDTO(id: "new-1"))])
    let repo = ListingRepositoryImpl(apiClient: client)
    let draft = CreateListingDraft(categoryId: "cat-1", title: "2019 BMW", description: nil, price: 85000, currency: "SAR", attributes: ["brand": .string("bmw")])

    let listing = try await repo.createListing(draft)

    #expect(listing.id == "new-1")
    #expect(listing.attributesIndex["brand"] == .string("bmw"))
    #expect(listing.attributesIndex["mileage"] == .number(84000))
    #expect(listing.attributesIndex["featured"] == .bool(true))
}

@Test func listingRepositoryFetchesASingleListingByPath() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/listings/l-42", value: makeListingDTO(id: "l-42"))])
    let repo = ListingRepositoryImpl(apiClient: client)

    let listing = try await repo.fetchListing(id: "l-42")

    #expect(listing.id == "l-42")
    #expect(listing.status == .draft)
}

@Test func listingRepositoryFetchesAFilteredPageAndMapsPagination() async throws {
    let client = RoutedFakeAPIClient(routes: [
        .init(
            pathContains: "/v1/listings", value: nil,
            collection: (items: [makeListingDTO(status: "published")], page: PaginationMetaMock(nextCursor: "cursor-2", hasMore: true).meta)
        ),
    ])
    let repo = ListingRepositoryImpl(apiClient: client)

    let page = try await repo.fetchListings(filters: ListingFilters(categoryId: "cat-1"))

    #expect(page.items.first?.status == .published)
    #expect(page.nextCursor == "cursor-2")
    #expect(page.hasMore == true)
}

@Test func listingRepositoryMineFilterRequiresAuthAndSendsOwnerMe() async throws {
    let client = RoutedFakeAPIClient(routes: [
        .init(pathContains: "/v1/listings", value: nil, collection: (items: [], page: PaginationMetaMock(nextCursor: nil, hasMore: false).meta)),
    ])
    let repo = ListingRepositoryImpl(apiClient: client)

    _ = try await repo.fetchListings(filters: ListingFilters(mine: true))

    #expect(client.lastRequiredAuth == true)
    #expect(client.lastPath == "/v1/listings")
}

@Test func listingRepositoryUpdatesStatus() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/listings/l-1", value: makeListingDTO(id: "l-1", status: "published"))])
    let repo = ListingRepositoryImpl(apiClient: client)

    let listing = try await repo.updateStatus(listingId: "l-1", status: .published)

    #expect(listing.status == .published)
}

@Test func listingRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/listings/l-1", value: nil, error: Boom())])
    let repo = ListingRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.fetchListing(id: "l-1")
    }
}

@Test func listingRepositoryEncodesEqualityAndRangeFilters() {
    let filtersJSON = ListingRepositoryImpl.encodeFilters([
        "brand": .equals(.string("bmw")),
        "mileage": .range(AttributeRangeFilter(lt: 100_000)),
    ])

    #expect(filtersJSON != nil)
    #expect(filtersJSON!.contains("\"brand\":\"bmw\""))
    #expect(filtersJSON!.contains("\"lt\":100000"))
}

private struct PaginationMetaMock {
    let nextCursor: String?
    let hasMore: Bool
    var meta: PaginationMeta {
        let json = """
        {"nextCursor": \(nextCursor.map { "\"\($0)\"" } ?? "null"), "hasMore": \(hasMore)}
        """
        return try! JSONDecoder().decode(PaginationMeta.self, from: json.data(using: .utf8)!)
    }
}
