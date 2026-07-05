/// Bundles chat's four operations for `Presentation` — like `CatalogUseCase`,
/// one cohesive entry point since none of the four carry logic beyond the
/// repository call itself.
public protocol ChatUseCase: Sendable {
    func fetchConversations() async throws -> [Conversation]
    func startConversation(listingId: String) async throws -> Conversation
    func fetchMessages(conversationId: String) async throws -> [Message]
    func sendMessage(conversationId: String, body: String) async throws -> Message
}

public struct DefaultChatUseCase: ChatUseCase {
    private let chatRepository: ChatRepository

    public init(chatRepository: ChatRepository) {
        self.chatRepository = chatRepository
    }

    public func fetchConversations() async throws -> [Conversation] {
        try await chatRepository.fetchConversations()
    }

    public func startConversation(listingId: String) async throws -> Conversation {
        try await chatRepository.startConversation(listingId: listingId)
    }

    public func fetchMessages(conversationId: String) async throws -> [Message] {
        try await chatRepository.fetchMessages(conversationId: conversationId)
    }

    public func sendMessage(conversationId: String, body: String) async throws -> Message {
        try await chatRepository.sendMessage(conversationId: conversationId, body: body)
    }
}
