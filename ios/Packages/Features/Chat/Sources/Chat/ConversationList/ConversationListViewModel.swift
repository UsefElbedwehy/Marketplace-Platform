import Core
import DomainKit
import Observation

@Observable
@MainActor
final class ConversationListViewModel {
    private(set) var conversations: [Conversation] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var currentUserId: String?

    private let chatUseCase: ChatUseCase
    private let authUseCase: AuthUseCase

    init(chatUseCase: ChatUseCase = Container.shared.chatUseCase(), authUseCase: AuthUseCase = Container.shared.authUseCase()) {
        self.chatUseCase = chatUseCase
        self.authUseCase = authUseCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        // A local Keychain read, not worth async-let-parallelizing with the
        // network call below.
        currentUserId = await authUseCase.currentSession()?.sub
        do {
            conversations = try await chatUseCase.fetchConversations()
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func otherPartyDisplayName(for conversation: Conversation) -> String {
        guard let currentUserId else { return conversation.sellerDisplayName ?? "Unknown" }
        return conversation.otherParticipantDisplayName(viewerId: currentUserId) ?? "Unknown"
    }
}
