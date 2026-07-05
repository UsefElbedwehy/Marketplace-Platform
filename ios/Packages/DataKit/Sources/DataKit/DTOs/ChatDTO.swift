/// Decodes the contract's `Conversation`/`Message`. `ChatRepositoryImpl` maps
/// these onto `DomainKit.Conversation`/`DomainKit.Message`.
struct ConversationDTO: Decodable {
    let id: String
    let listingId: String
    let listingTitle: String
    let buyerId: String
    let buyerDisplayName: String?
    let sellerId: String
    let sellerDisplayName: String?
    let lastMessageAt: String?
    let createdAt: String
}

struct MessageDTO: Decodable {
    let id: String
    let conversationId: String
    let senderId: String
    let body: String
    let readAt: String?
    let createdAt: String
}

/// What `POST /v1/chat/conversations` accepts.
struct StartConversationRequestDTO: Encodable {
    let listingId: String
}

/// What `POST /v1/chat/conversations/{id}/messages` accepts.
struct SendMessageRequestDTO: Encodable {
    let body: String
}
