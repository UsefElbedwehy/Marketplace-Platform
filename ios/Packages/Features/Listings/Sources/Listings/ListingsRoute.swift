import DomainKit

/// The public surface a host `NavigationStack` (the App's `TabCoordinator`)
/// pushes — per ADR-0015, "each feature package exposes... its route enum."
public enum ListingsRoute: Hashable, Sendable {
    case createListing
    case detail(listingId: String)
    case myListings
    /// A listing's seller — pushed from `ListingDetailView`. `SellerProfileView`
    /// lives in this package (reachable only from a listing detail today), so
    /// the App's per-tab `navigationDestination` handles this case directly.
    case sellerProfile(sellerId: String)
    /// Carries the full `Conversation` (not just an id) since both places
    /// that navigate here — `ListingDetailView`'s "Message seller" and
    /// `Features/Chat`'s own conversation list — already have it in hand,
    /// avoiding a redundant fetch. The App's per-tab `navigationDestination`
    /// pushes `Chat.MessageThreadView(conversation:)` for this case.
    case conversation(Conversation)
}
