import Chat
import DomainKit
import Listings
import SwiftUI

/// "My listings" + moderation queue (mirrors the dashboard's `/listings`
/// page) with a "+" that pushes the schema-driven create-listing flow.
/// `MyListingsViewModel` resolves whether the signed-in identity sees the
/// moderation queue itself (see its `load()` doc comment) — deriving it here
/// instead, into a `@State` passed to `MyListingsView`'s init, previously
/// raced the session lookup: the view's `@State` locks in whatever value was
/// passed at first render, and never picks up the value an async `.task`
/// resolves afterwards.
struct SellTabView: View {
    @Binding var path: NavigationPath

    var body: some View {
        MyListingsView { listing in
            path.append(ListingsRoute.detail(listingId: listing.id))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    path.append(ListingsRoute.createListing)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("sell.new-listing")
            }
        }
        .navigationDestination(for: ListingsRoute.self) { route in
            switch route {
            case .detail(let listingId):
                ListingDetailView(listingId: listingId) { conversation in
                    path.append(ListingsRoute.conversation(conversation))
                }
            case .sellerProfile(let sellerId):
                SellerProfileView(sellerId: sellerId)
            case .conversation(let conversation):
                MessageThreadView(conversation: conversation)
            case .createListing:
                CreateListingView { _ in
                    path.removeLast()
                }
            case .myListings:
                EmptyView() // this tab's own root, never pushed onto itself
            }
        }
    }
}
