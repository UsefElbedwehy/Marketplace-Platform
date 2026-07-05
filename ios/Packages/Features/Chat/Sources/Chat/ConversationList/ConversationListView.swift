import DesignSystem
import DomainKit
import SwiftUI

/// The Chat tab's root ⭐ (Phase 6 golden-path exit criterion: "buyer↔seller
/// chat on a listing"). Poll-based — refetches on appear and pull-to-refresh,
/// not a live subscription (see `ChatRoute`'s/`ChatRepository`'s doc
/// comments for why).
public struct ConversationListView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = ConversationListViewModel()
    let onSelect: (Conversation) -> Void

    public init(onSelect: @escaping (Conversation) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                LoadingIndicator()
            } else if let error = viewModel.errorMessage {
                ErrorStateView(message: error) { Task { await viewModel.load() } }
            } else if viewModel.conversations.isEmpty {
                EmptyStateView(title: "No conversations yet", message: "Message a seller from a listing to start one.")
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.conversations) { conversation in
                        Button { onSelect(conversation) } label: {
                            ConversationRowView(conversation: conversation, otherPartyName: viewModel.otherPartyDisplayName(for: conversation))
                        }
                        .accessibilityIdentifier("conversation-row.\(conversation.id)")
                    }
                }
                .padding(16)
            }
        }
        .background(colors.background)
        .navigationTitle("Chat")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct ConversationRowView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let conversation: Conversation
    let otherPartyName: String

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(otherPartyName).font(theme.typography.headline.font).foregroundStyle(colors.textPrimary)
                    Text(conversation.listingTitle).font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(colors.textSecondary)
            }
        }
    }
}
