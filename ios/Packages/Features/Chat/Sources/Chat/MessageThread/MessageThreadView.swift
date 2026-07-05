import DesignSystem
import DomainKit
import SwiftUI

public struct MessageThreadView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = MessageThreadViewModel()
    let conversation: Conversation

    public init(conversation: Conversation) {
        self.conversation = conversation
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                if viewModel.isLoading {
                    LoadingIndicator()
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) { Task { await viewModel.refresh(conversationId: conversation.id) } }
                } else {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message, isFromCurrentUser: viewModel.isFromCurrentUser(message))
                        }
                    }
                    .padding(16)
                    .accessibilityIdentifier("message-thread.messages")
                }
            }

            HStack(spacing: 8) {
                AppTextField("Message…", text: $viewModel.draftBody)
                    .accessibilityIdentifier("message-thread.input")
                Button {
                    Task { await viewModel.send(conversationId: conversation.id) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title)
                }
                .disabled(viewModel.isSending || viewModel.draftBody.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityIdentifier("message-thread.send")
            }
            .padding(12)
            .background(colors.surface)
        }
        .background(colors.background)
        .navigationTitle(conversation.listingTitle)
        .task {
            await viewModel.load(conversationId: conversation.id)
            viewModel.startPolling(conversationId: conversation.id)
        }
        .onDisappear { viewModel.stopPolling() }
    }
}

private struct MessageBubbleView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 40) }
            Text(message.body)
                .font(theme.typography.body.font)
                .foregroundStyle(isFromCurrentUser ? colors.background : colors.textPrimary)
                .padding(12)
                .background(isFromCurrentUser ? colors.primary : colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusMedium))
            if !isFromCurrentUser { Spacer(minLength: 40) }
        }
        .accessibilityIdentifier("message-bubble.\(message.id)")
    }
}
