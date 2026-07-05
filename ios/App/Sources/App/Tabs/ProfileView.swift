import Chat
import Core
import DesignSystem
import DomainKit
import Listings
import SwiftUI

struct ProfileView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let coordinator: AppCoordinator
    @Binding var path: NavigationPath
    @State private var session: AuthSession?
    @State private var isSigningOut = false

    @Injected(\.authUseCase) private var authUseCase

    var body: some View {
        VStack(spacing: 20) {
            if let session {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(session.displayName)
                            .font(theme.typography.headline.font)
                            .foregroundStyle(colors.textPrimary)
                        Text("app_role: \(session.appRole)")
                            .font(theme.typography.footnote.font)
                            .foregroundStyle(colors.textSecondary)
                            .accessibilityIdentifier("profile.appRole")
                        Text("tenant_id: \(session.tenantId)")
                            .font(theme.typography.footnote.font)
                            .foregroundStyle(colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
            }

            VStack(spacing: 12) {
                NavigationLink(value: ProfileRoute.savedListings) {
                    profileRow(title: "Saved listings", systemImage: "heart")
                }
                .accessibilityIdentifier("profile.saved-listings")

                NavigationLink(value: ProfileRoute.notifications) {
                    profileRow(title: "Notifications", systemImage: "bell")
                }
                .accessibilityIdentifier("profile.notifications")
            }
            .padding(.horizontal, 20)

            SecondaryButton(isSigningOut ? "Signing out…" : "Sign out") {
                Task {
                    isSigningOut = true
                    await coordinator.signOut()
                    isSigningOut = false
                }
            }
            .padding(.horizontal, 20)
            .disabled(isSigningOut)

            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background)
        .navigationTitle("Profile")
        .task {
            session = await authUseCase.currentSession()
        }
        .navigationDestination(for: ProfileRoute.self) { route in
            switch route {
            case .savedListings:
                SavedListingsView { listing in
                    path.append(ListingsRoute.detail(listingId: listing.id))
                }
            case .notifications:
                NotificationsListView()
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
            case .createListing, .myListings:
                EmptyView() // not reachable from Profile
            }
        }
    }

    private func profileRow(title: String, systemImage: String) -> some View {
        Card {
            HStack {
                Image(systemName: systemImage).foregroundStyle(colors.textPrimary)
                Text(title).font(theme.typography.subheadline.font).foregroundStyle(colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(colors.textSecondary)
            }
        }
    }
}
