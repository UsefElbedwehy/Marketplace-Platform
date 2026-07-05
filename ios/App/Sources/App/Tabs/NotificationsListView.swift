import Core
import DesignSystem
import DomainKit
import SwiftUI

/// The in-app notification list ⭐ (Phase 6 golden-path exit criterion:
/// "receive a push" — `deliveredAt` reflects a logging no-op push adapter,
/// not real APNs delivery; see `NotificationsRepository`'s doc comment).
/// Reached from the Profile tab. Lives directly in the App target rather
/// than its own Feature package — a single flat list with no reuse needs
/// beyond what `DesignSystem` already provides, unlike Chat/Listings.
struct NotificationsListView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Injected(\.notificationsUseCase) private var notificationsUseCase

    var body: some View {
        ScrollView {
            if isLoading {
                LoadingIndicator()
            } else if let errorMessage {
                ErrorStateView(message: errorMessage) { Task { await load() } }
            } else if notifications.isEmpty {
                EmptyStateView(title: "No notifications", message: "New messages and updates will show up here.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(notifications) { notification in
                        NotificationRowView(notification: notification)
                            .accessibilityIdentifier("notification-row.\(notification.id)")
                            .onTapGesture { Task { await markRead(notification) } }
                    }
                }
                .padding(16)
            }
        }
        .background(colors.background)
        .navigationTitle("Notifications")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notifications = try await notificationsUseCase.fetchNotifications()
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    private func markRead(_ notification: AppNotification) async {
        guard notification.readAt == nil else { return }
        if let updated = try? await notificationsUseCase.markRead(id: notification.id),
           let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = updated
        }
    }
}

private struct NotificationRowView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let notification: AppNotification

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(theme.typography.subheadline.font).foregroundStyle(colors.textPrimary)
                    Text(notification.createdAt).font(theme.typography.footnote.font).foregroundStyle(colors.textSecondary)
                }
                Spacer()
                if notification.readAt == nil {
                    Circle().fill(colors.primary).frame(width: 8, height: 8)
                }
            }
        }
    }

    private var title: String {
        switch notification.type {
        case .chatMessage: return "New message"
        case .listingFavorited: return "Someone favorited your listing"
        case .reviewReceived: return "You received a review"
        }
    }
}
