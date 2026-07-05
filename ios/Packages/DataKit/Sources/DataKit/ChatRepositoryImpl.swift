import Core
import DomainKit
import Networking

/// Fulfils `DomainKit.ChatRepository` — the only place `ConversationDTO`/
/// `MessageDTO` translate to/from `DomainKit.Conversation`/`DomainKit.Message`.
/// Poll-based REST, not Realtime — see `ChatRepository`'s doc comment.
public struct ChatRepositoryImpl: ChatRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchConversations() async throws -> [Conversation] {
        do {
            let endpoint = APIEndpoint(path: "/v1/chat/conversations")
            let dtos: [ConversationDTO] = try await apiClient.send(endpoint, decodingTo: [ConversationDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func startConversation(listingId: String) async throws -> Conversation {
        do {
            let endpoint = try APIEndpoint.encoding(
                StartConversationRequestDTO(listingId: listingId), path: "/v1/chat/conversations", method: .post
            )
            let dto: ConversationDTO = try await apiClient.send(endpoint, decodingTo: ConversationDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func fetchMessages(conversationId: String) async throws -> [Message] {
        do {
            let endpoint = APIEndpoint(path: "/v1/chat/conversations/\(conversationId)/messages")
            let dtos: [MessageDTO] = try await apiClient.send(endpoint, decodingTo: [MessageDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func sendMessage(conversationId: String, body: String) async throws -> Message {
        do {
            let endpoint = try APIEndpoint.encoding(
                SendMessageRequestDTO(body: body), path: "/v1/chat/conversations/\(conversationId)/messages", method: .post
            )
            let dto: MessageDTO = try await apiClient.send(endpoint, decodingTo: MessageDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: ConversationDTO) -> Conversation {
        Conversation(
            id: dto.id, listingId: dto.listingId, listingTitle: dto.listingTitle,
            buyerId: dto.buyerId, buyerDisplayName: dto.buyerDisplayName,
            sellerId: dto.sellerId, sellerDisplayName: dto.sellerDisplayName,
            lastMessageAt: dto.lastMessageAt, createdAt: dto.createdAt
        )
    }

    static func map(_ dto: MessageDTO) -> Message {
        Message(
            id: dto.id, conversationId: dto.conversationId, senderId: dto.senderId,
            body: dto.body, readAt: dto.readAt, createdAt: dto.createdAt
        )
    }
}
