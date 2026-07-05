import DesignSystem
import DomainKit
import SwiftUI

/// Mirrors `dashboard/src/app/listings/page.tsx` on iOS: "my listings" with
/// role-appropriate transition actions, plus a moderator's approve/reject
/// queue when the signed-in identity has that privilege.
public struct MyListingsView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = MyListingsViewModel()
    let onSelect: (Listing) -> Void

    public init(onSelect: @escaping (Listing) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let error = viewModel.errorMessage {
                    Text(error).font(theme.typography.footnote.font).foregroundStyle(colors.danger)
                }

                if viewModel.isModerator {
                    section(title: "Moderation queue (\(viewModel.moderationQueue.count))", listings: viewModel.moderationQueue) { listing in
                        HStack {
                            SecondaryButton("Approve") { Task { await viewModel.transition(listing, to: .published) } }
                            SecondaryButton("Reject") { Task { await viewModel.transition(listing, to: .rejected) } }
                        }
                    }
                }

                section(title: "My listings", listings: viewModel.mine) { listing in
                    HStack {
                        ForEach(OwnerAction.actions(for: listing.status), id: \.self) { action in
                            SecondaryButton(action.rawValue) { Task { await viewModel.transition(listing, to: action.target) } }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(colors.background)
        .navigationTitle("My listings")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private func section(title: String, listings: [Listing], @ViewBuilder actions: @escaping (Listing) -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased()).font(theme.typography.caption.font).foregroundStyle(colors.textSecondary)
            if listings.isEmpty && !viewModel.isLoading {
                Text("Nothing here yet.").font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
            }
            ForEach(listings) { listing in
                VStack(alignment: .leading, spacing: 8) {
                    Button { onSelect(listing) } label: { ListingRowView(listing: listing) }
                    if viewModel.busyListingId == listing.id {
                        LoadingIndicator()
                    } else {
                        actions(listing)
                    }
                }
                // Without `.contain`, attaching an accessibility identifier
                // directly to this VStack collapses the whole row (title +
                // every action button) into one opaque element — hiding the
                // action buttons from VoiceOver and UI tests alike.
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("my-listing-row.\(listing.id)")
            }
        }
    }
}
