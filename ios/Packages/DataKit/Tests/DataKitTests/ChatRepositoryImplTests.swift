import Testing
import Core
import Networking
@testable import DataKit
@testable import DomainKit

func makeConversationDTO(id: String = "c1") -> ConversationDTO {
    ConversationDTO(
        id: id, listingId: "l1", listingTitle: "2019 BMW", buyerId: "buyer-1", buyerDisplayName: "Dev Buyer",
        sellerId: "seller-1", sellerDisplayName: "Dev Seller", lastMessageAt: nil, createdAt: "2026-01-01T00:00:00Z"
    )
}

func makeMessageDTO(id: String = "m1", body: String = "hi") -> MessageDTO {
    MessageDTO(id: id, conversationId: "c1", senderId: "buyer-1", body: body, readAt: nil, createdAt: "2026-01-01T00:00:00Z")
}

@Test func chatRepositoryStartsAConversation() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/chat/conversations", value: makeConversationDTO(id: "new-c"))])
    let repo = ChatRepositoryImpl(apiClient: client)

    let conversation = try await repo.startConversation(listingId: "l1")

    #expect(conversation.id == "new-c")
    #expect(conversation.otherParticipantDisplayName(viewerId: "buyer-1") == "Dev Seller")
    #expect(conversation.otherParticipantDisplayName(viewerId: "seller-1") == "Dev Buyer")
}

@Test func chatRepositorySendsAMessage() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/chat/conversations/c1/messages", value: makeMessageDTO(body: "Is this still available?"))])
    let repo = ChatRepositoryImpl(apiClient: client)

    let message = try await repo.sendMessage(conversationId: "c1", body: "Is this still available?")

    #expect(message.body == "Is this still available?")
    #expect(message.conversationId == "c1")
}

@Test func chatRepositoryFetchesConversationsAsACollection() async throws {
    let client = RoutedFakeAPIClient(routes: [
        .init(pathContains: "/v1/chat/conversations", value: [makeConversationDTO(), makeConversationDTO(id: "c2")]),
    ])
    let repo = ChatRepositoryImpl(apiClient: client)

    let conversations = try await repo.fetchConversations()

    #expect(conversations.count == 2)
}

@Test func chatRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/chat/conversations", value: nil, error: Boom())])
    let repo = ChatRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.fetchConversations()
    }
}
