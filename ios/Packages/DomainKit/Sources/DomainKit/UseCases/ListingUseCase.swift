/// Bundles listing create/fetch/browse/moderate for `Presentation` — see
/// `CatalogUseCase`'s doc comment for why these are grouped rather than
/// split into near-empty pass-through use cases.
public protocol ListingUseCase: Sendable {
    func createListing(_ draft: CreateListingDraft) async throws -> Listing
    func fetchListing(id: String) async throws -> Listing
    func fetchListings(filters: ListingFilters) async throws -> Page<Listing>
    func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing
}

public struct DefaultListingUseCase: ListingUseCase {
    private let listingRepository: ListingRepository

    public init(listingRepository: ListingRepository) {
        self.listingRepository = listingRepository
    }

    public func createListing(_ draft: CreateListingDraft) async throws -> Listing {
        try await listingRepository.createListing(draft)
    }

    public func fetchListing(id: String) async throws -> Listing {
        try await listingRepository.fetchListing(id: id)
    }

    public func fetchListings(filters: ListingFilters) async throws -> Page<Listing> {
        try await listingRepository.fetchListings(filters: filters)
    }

    public func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing {
        try await listingRepository.updateStatus(listingId: listingId, status: status)
    }
}
