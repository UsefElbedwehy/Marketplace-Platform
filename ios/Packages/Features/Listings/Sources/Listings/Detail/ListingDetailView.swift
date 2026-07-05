import DesignSystem
import DomainKit
import SwiftUI

/// Schema-projected read-only detail — the same `ComposedSchema` that drives
/// `CreateListingView`'s form also drives which rows show up here and in
/// what order/units, for any category (docs/planning/05 §6).
public struct ListingDetailView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = ListingDetailViewModel()
    let listingId: String
    /// Set by the App's per-tab `navigationDestination` once "Message
    /// seller" resolves a conversation — pushes `ListingsRoute.conversation`.
    let onConversationStarted: (Conversation) -> Void

    public init(listingId: String, onConversationStarted: @escaping (Conversation) -> Void = { _ in }) {
        self.listingId = listingId
        self.onConversationStarted = onConversationStarted
    }

    public var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingIndicator()
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load(listingId: listingId) } }
            } else if let listing = viewModel.listing {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text(listing.title).font(theme.typography.title2.font).foregroundStyle(colors.textPrimary)
                            Spacer()
                            favoriteButton
                        }
                        if let price = listing.price {
                            Text("\(Self.formatted(price)) \(listing.currency ?? "")")
                                .font(theme.typography.headline.font)
                                .foregroundStyle(colors.primary)
                        }
                        Badge(listing.status.rawValue)
                    }

                    if let description = listing.description, !description.isEmpty {
                        Text(description).font(theme.typography.body.font).foregroundStyle(colors.textSecondary)
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.attributeRows, id: \.label) { row in
                                HStack {
                                    Text(row.label).font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
                                    Spacer()
                                    Text(row.value).font(theme.typography.subheadline.font).foregroundStyle(colors.textPrimary)
                                }
                            }
                        }
                    }

                    sellerSection(listing: listing)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(colors.background)
        .navigationTitle("Listing")
        .task { await viewModel.load(listingId: listingId) }
    }

    private var favoriteButton: some View {
        Button {
            Task { await viewModel.toggleFavorite() }
        } label: {
            Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                .foregroundStyle(viewModel.isFavorited ? colors.danger : colors.textSecondary)
        }
        .disabled(viewModel.isTogglingFavorite)
        .accessibilityIdentifier("listing-detail.favorite-toggle")
    }

    private func sellerSection(listing: Listing) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("SELLER").font(theme.typography.caption.font).foregroundStyle(colors.textSecondary)
                NavigationLink(value: ListingsRoute.sellerProfile(sellerId: listing.ownerId)) {
                    HStack {
                        Text("View seller profile").font(theme.typography.subheadline.font).foregroundStyle(colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(colors.textSecondary)
                    }
                }
                .accessibilityIdentifier("listing-detail.seller-profile-link")

                PrimaryButton(viewModel.isStartingConversation ? "Starting…" : "Message seller", isLoading: viewModel.isStartingConversation) {
                    Task {
                        if let conversation = await viewModel.startConversationWithSeller() {
                            onConversationStarted(conversation)
                        }
                    }
                }
                .disabled(viewModel.isStartingConversation)
                .accessibilityIdentifier("listing-detail.message-seller")
            }
        }
    }

    private static func formatted(_ price: Double) -> String {
        price.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(price)) : String(price)
    }
}
