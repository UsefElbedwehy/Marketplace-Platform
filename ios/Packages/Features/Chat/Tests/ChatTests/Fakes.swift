import DomainKit
@testable import Chat

actor StubChatUseCase: ChatUseCase {
    var conversations: [Conversation] = []
    var conversation: Conversation = .fixture()
    var messages: [Message] = []
    var sentMessage: Message = .fixture()
    var error: Error?
    var sendMessageCalls: [(conversationId: String, body: String)] = []

    init(conversations: [Conversation] = [], messages: [Message] = [], sentMessage: Message = .fixture(), error: Error? = nil) {
        self.conversations = conversations
        self.messages = messages
        self.sentMessage = sentMessage
        self.error = error
    }

    func fetchConversations() async throws -> [Conversation] {
        if let error { throw error }
        return conversations
    }

    func startConversation(listingId: String) async throws -> Conversation {
        if let error { throw error }
        return conversation
    }

    func fetchMessages(conversationId: String) async throws -> [Message] {
        if let error { throw error }
        return messages
    }

    func sendMessage(conversationId: String, body: String) async throws -> Message {
        if let error { throw error }
        sendMessageCalls.append((conversationId, body))
        return sentMessage
    }
}

struct StubAuthUseCase: AuthUseCase {
    var session: AuthSession?

    func currentSession() async -> AuthSession? { session }
    func signIn(as identity: DevIdentity) async throws -> AuthSession { .fixture() }
    func signOut() async {}
}

extension AuthSession {
    static func fixture(sub: String = "buyer-1", appRole: String = "buyer") -> AuthSession {
        AuthSession(accessToken: "token", sub: sub, tenantId: "tenant-1", appRole: appRole, displayName: "Dev User")
    }
}

extension Conversation {
    static func fixture(id: String = "c1") -> Conversation {
        Conversation(
            id: id, listingId: "l1", listingTitle: "2019 BMW", buyerId: "buyer-1", buyerDisplayName: "Dev Buyer",
            sellerId: "seller-1", sellerDisplayName: "Dev Seller", lastMessageAt: nil, createdAt: "2026-01-01T00:00:00Z"
        )
    }
}

extension Message {
    static func fixture(id: String = "m1", senderId: String = "buyer-1", body: String = "hi") -> Message {
        Message(id: id, conversationId: "c1", senderId: senderId, body: body, readAt: nil, createdAt: "2026-01-01T00:00:00Z")
    }
}
