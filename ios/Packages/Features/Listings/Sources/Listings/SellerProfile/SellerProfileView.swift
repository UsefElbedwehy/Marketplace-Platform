import DesignSystem
import DomainKit
import SwiftUI

/// A seller's PUBLIC profile ⭐ (Phase 6 golden-path exit criterion). Reached
/// from `ListingDetailView`'s "View seller profile" link.
public struct SellerProfileView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = SellerProfileViewModel()
    @State private var isComposingReview = false
    let sellerId: String

    public init(sellerId: String) {
        self.sellerId = sellerId
    }

    public var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingIndicator()
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load(sellerId: sellerId) } }
            } else if let profile = viewModel.profile {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader(profile: profile)
                    PrimaryButton("Leave a review") { isComposingReview = true }
                        .accessibilityIdentifier("seller-profile.leave-review")
                    reviewsSection
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(colors.background)
        .navigationTitle(viewModel.profile?.displayName ?? "Seller")
        .task { await viewModel.load(sellerId: sellerId) }
        .sheet(isPresented: $isComposingReview) {
            ReviewComposerView(sellerId: sellerId, viewModel: viewModel)
        }
    }

    private func profileHeader(profile: SellerProfile) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(profile.displayName ?? "Seller").font(theme.typography.title2.font).foregroundStyle(colors.textPrimary)
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio).font(theme.typography.body.font).foregroundStyle(colors.textSecondary)
                }
                HStack(spacing: 16) {
                    if let average = profile.ratingAverage {
                        Label("\(String(format: "%.1f", average)) (\(profile.ratingCount))", systemImage: "star.fill")
                            .font(theme.typography.subheadline.font)
                            .foregroundStyle(colors.warning)
                            .accessibilityIdentifier("seller-profile.rating")
                    } else {
                        Text("No ratings yet").font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
                    }
                    Text("\(profile.publishedListingCount) listings").font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REVIEWS (\(viewModel.reviews.count))").font(theme.typography.caption.font).foregroundStyle(colors.textSecondary)
            if viewModel.reviews.isEmpty {
                Text("No reviews yet.").font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
            }
            ForEach(viewModel.reviews) { review in
                Card {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(review.reviewerDisplayName ?? "Buyer").font(theme.typography.subheadline.font).foregroundStyle(colors.textPrimary)
                            Spacer()
                            Label("\(review.rating)", systemImage: "star.fill").font(theme.typography.footnote.font).foregroundStyle(colors.warning)
                        }
                        if let comment = review.comment, !comment.isEmpty {
                            Text(comment).font(theme.typography.footnote.font).foregroundStyle(colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

private struct ReviewComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var rating = 5
    @State private var comment = ""
    let sellerId: String
    let viewModel: SellerProfileViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Rate this seller").font(theme.typography.headline.font).foregroundStyle(colors.textPrimary)
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            rating = star
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundStyle(colors.warning)
                                .font(.title2)
                        }
                        .accessibilityIdentifier("review-composer.star.\(star)")
                    }
                }
                AppTextField("Comment (optional)", text: $comment)
                if let error = viewModel.errorMessage {
                    Text(error).font(theme.typography.footnote.font).foregroundStyle(colors.danger)
                }
                PrimaryButton(viewModel.isSubmittingReview ? "Submitting…" : "Submit review", isLoading: viewModel.isSubmittingReview) {
                    Task {
                        await viewModel.submitReview(sellerId: sellerId, rating: rating, comment: comment.isEmpty ? nil : comment)
                        if viewModel.reviewSubmitted { dismiss() }
                    }
                }
                .disabled(viewModel.isSubmittingReview)
                .accessibilityIdentifier("review-composer.submit")
                Spacer()
            }
            .padding(20)
            .background(colors.background)
            .navigationTitle("Leave a review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
