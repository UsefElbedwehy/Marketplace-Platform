import Chat
import DomainKit
import Listings
import SwiftUI

/// Home = browse published listings — the feed. Reuses `Listings`'
/// `ListingFeedView`/`ListingDetailView`/`SellerProfileView` and `Chat`'s
/// `MessageThreadView` unmodified; this file is just the tab's navigation
/// wiring (App is the only place allowed to know about more than one
/// Feature module at once).
struct HomeTabView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ListingFeedView { listing in
            path.append(ListingsRoute.detail(listingId: listing.id))
        }
        .navigationTitle("Home")
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
            case .createListing, .myListings:
                EmptyView() // not reachable from Home
            }
        }
    }
}
