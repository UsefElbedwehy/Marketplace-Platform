import DesignSystem
import DomainKit
import SwiftUI

/// Favorites ⭐ (Phase 6 golden-path exit criterion: "favorite/unfavorite")
/// — a buyer's saved listings, reached from the Profile tab.
public struct SavedListingsView: View {
    @Environment(\.semanticColors) private var colors
    @State private var viewModel = SavedListingsViewModel()
    let onSelect: (Listing) -> Void

    public init(onSelect: @escaping (Listing) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingIndicator()
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load() } }
            } else if viewModel.listings.isEmpty {
                EmptyStateView(title: "No saved listings", message: "Listings you favorite will show up here.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.listings) { listing in
                        VStack(alignment: .leading, spacing: 8) {
                            Button { onSelect(listing) } label: { ListingRowView(listing: listing) }
                            SecondaryButton("Remove") {
                                Task { await viewModel.removeFavorite(listingId: listing.id) }
                            }
                        }
                        .accessibilityIdentifier("saved-listing-row.\(listing.id)")
                    }
                }
                .padding(16)
            }
        }
        .background(colors.background)
        .navigationTitle("Saved")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}
