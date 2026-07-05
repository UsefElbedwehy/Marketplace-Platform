import Core
import DomainKit
import Observation

@Observable
@MainActor
final class ListingFeedViewModel {
    private(set) var listings: [Listing] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var hasMore = false
    private var nextCursor: String?
    private var baseFilters: ListingFilters

    private let listingUseCase: ListingUseCase

    init(filters: ListingFilters = ListingFilters(), listingUseCase: ListingUseCase = Container.shared.listingUseCase()) {
        self.baseFilters = filters
        self.listingUseCase = listingUseCase
    }

    func loadFirstPage() async {
        listings = []
        nextCursor = nil
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var filters = baseFilters
            filters.cursor = nextCursor
            let page = try await listingUseCase.fetchListings(filters: filters)
            listings += page.items
            nextCursor = page.nextCursor
            hasMore = page.hasMore
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func applyFilters(_ filters: ListingFilters) {
        baseFilters = filters
    }
}
