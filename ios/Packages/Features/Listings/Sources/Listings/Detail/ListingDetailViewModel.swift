import Core
import DomainKit
import Observation

@Observable
@MainActor
final class ListingDetailViewModel {
    private(set) var listing: Listing?
    private(set) var schema: ComposedSchema?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var isFavorited = false
    private(set) var isTogglingFavorite = false
    private(set) var isStartingConversation = false

    private let listingUseCase: ListingUseCase
    private let catalogUseCase: CatalogUseCase
    private let favoritesUseCase: FavoritesUseCase
    private let chatUseCase: ChatUseCase

    init(
        listingUseCase: ListingUseCase = Container.shared.listingUseCase(),
        catalogUseCase: CatalogUseCase = Container.shared.catalogUseCase(),
        favoritesUseCase: FavoritesUseCase = Container.shared.favoritesUseCase(),
        chatUseCase: ChatUseCase = Container.shared.chatUseCase()
    ) {
        self.listingUseCase = listingUseCase
        self.catalogUseCase = catalogUseCase
        self.favoritesUseCase = favoritesUseCase
        self.chatUseCase = chatUseCase
    }

    func load(listingId: String, locale: String = "en") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let listing = try await listingUseCase.fetchListing(id: listingId)
            self.listing = listing
            async let schemaTask = catalogUseCase.fetchSchema(categoryId: listing.categoryId, locale: locale)
            async let favoritesTask = favoritesUseCase.fetchFavorites()
            let (schema, favorites) = try await (schemaTask, favoritesTask)
            self.schema = schema
            self.isFavorited = favorites.contains { $0.listingId == listingId }
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func toggleFavorite() async {
        guard let listing, !isTogglingFavorite else { return }
        isTogglingFavorite = true
        defer { isTogglingFavorite = false }
        do {
            if isFavorited {
                try await favoritesUseCase.removeFavorite(listingId: listing.id)
                isFavorited = false
            } else {
                _ = try await favoritesUseCase.addFavorite(listingId: listing.id)
                isFavorited = true
            }
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    /// Starts (or resumes) a conversation with this listing's seller —
    /// returns the conversation so the view can navigate to it, rather than
    /// owning navigation itself.
    func startConversationWithSeller() async -> Conversation? {
        guard let listing, !isStartingConversation else { return nil }
        isStartingConversation = true
        defer { isStartingConversation = false }
        do {
            return try await chatUseCase.startConversation(listingId: listing.id)
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
            return nil
        }
    }

    /// The schema-projected rows: each visible-by-default field's label +
    /// unit, resolved against the listing's raw `attributesIndex` — this is
    /// the "read-only detail view" half of the field-type registry
    /// (docs/planning/05-dynamic-schema-engine.md §6: "the exact same
    /// renderer + registry powers the filter sheet and read-only detail
    /// view").
    var attributeRows: [(label: String, value: String)] {
        guard let listing, let schema else { return [] }
        return schema.allFields
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .compactMap { field in
                guard let value = listing.attributesIndex[field.key] else { return nil }
                let display = field.unit.map { "\(value.displayString) \($0)" } ?? value.displayString
                return (field.label, display)
            }
    }
}
