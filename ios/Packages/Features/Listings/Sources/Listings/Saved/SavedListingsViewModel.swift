import Core
import DomainKit
import Observation

@Observable
@MainActor
final class SavedListingsViewModel {
    private(set) var listings: [Listing] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let favoritesUseCase: FavoritesUseCase
    private let listingUseCase: ListingUseCase

    init(favoritesUseCase: FavoritesUseCase = Container.shared.favoritesUseCase(), listingUseCase: ListingUseCase = Container.shared.listingUseCase()) {
        self.favoritesUseCase = favoritesUseCase
        self.listingUseCase = listingUseCase
    }

    // Favorites only carry a listingId — this is a small, low-traffic list
    // (a buyer's own saved items), so fetching each listing individually is
    // simpler than adding a bulk-fetch-by-ids endpoint for this alone.
    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let favorites = try await favoritesUseCase.fetchFavorites()
            listings = try await withThrowingTaskGroup(of: (Int, Listing).self) { group in
                for (index, favorite) in favorites.enumerated() {
                    group.addTask { (index, try await self.listingUseCase.fetchListing(id: favorite.listingId)) }
                }
                var results = [(Int, Listing)]()
                for try await result in group { results.append(result) }
                return results.sorted { $0.0 < $1.0 }.map(\.1)
            }
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func removeFavorite(listingId: String) async {
        do {
            try await favoritesUseCase.removeFavorite(listingId: listingId)
            listings.removeAll { $0.id == listingId }
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }
}
