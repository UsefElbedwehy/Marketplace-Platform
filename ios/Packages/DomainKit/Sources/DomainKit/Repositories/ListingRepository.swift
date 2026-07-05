/// Fulfilled in `DataKit` by wrapping `Networking`'s listings endpoints ⭐.
public protocol ListingRepository: Sendable {
    func createListing(_ draft: CreateListingDraft) async throws -> Listing
    func fetchListing(id: String) async throws -> Listing
    func fetchListings(filters: ListingFilters) async throws -> Page<Listing>
    func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing
}
