import Chat
import Listings
import Search
import SwiftUI

struct SearchTabView: View {
    @Binding var path: NavigationPath

    var body: some View {
        SearchView { listing in
            path.append(ListingsRoute.detail(listingId: listing.id))
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
            case .createListing, .myListings:
                EmptyView() // not reachable from Search
            }
        }
    }
}
