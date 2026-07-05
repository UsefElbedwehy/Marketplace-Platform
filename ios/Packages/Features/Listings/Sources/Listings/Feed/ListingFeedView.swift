import DesignSystem
import DomainKit
import SwiftUI

public struct ListingFeedView: View {
    @Environment(\.semanticColors) private var colors
    @State private var viewModel: ListingFeedViewModel
    let onSelect: (Listing) -> Void

    public init(filters: ListingFilters = ListingFilters(), onSelect: @escaping (Listing) -> Void) {
        _viewModel = State(initialValue: ListingFeedViewModel(filters: filters))
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) { Task { await viewModel.loadFirstPage() } }
                } else if viewModel.listings.isEmpty && !viewModel.isLoading {
                    EmptyStateView(title: "No listings yet", message: "Check back soon.")
                }

                ForEach(viewModel.listings) { listing in
                    Button { onSelect(listing) } label: {
                        ListingRowView(listing: listing)
                    }
                    .accessibilityIdentifier("listing-row.\(listing.id)")
                }

                if viewModel.hasMore {
                    ProgressView()
                        .onAppear { Task { await viewModel.loadNextPage() } }
                } else if viewModel.isLoading {
                    LoadingIndicator()
                }
            }
            .padding(16)
        }
        .background(colors.background)
        .task { await viewModel.loadFirstPage() }
        .refreshable { await viewModel.loadFirstPage() }
    }
}
