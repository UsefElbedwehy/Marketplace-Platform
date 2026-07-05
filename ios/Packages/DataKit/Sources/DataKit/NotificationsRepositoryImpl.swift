import Core
import DomainKit
import Networking

/// Fulfils `DomainKit.NotificationsRepository` — the only place
/// `NotificationDTO` translates to/from `DomainKit.AppNotification`. Poll-based
/// REST, not Realtime — see `NotificationsRepository`'s doc comment.
public struct NotificationsRepositoryImpl: NotificationsRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchNotifications() async throws -> [AppNotification] {
        do {
            let endpoint = APIEndpoint(path: "/v1/notifications")
            let dtos: [NotificationDTO] = try await apiClient.send(endpoint, decodingTo: [NotificationDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func markRead(id: String) async throws -> AppNotification {
        do {
            let endpoint = APIEndpoint(path: "/v1/notifications/\(id)", method: .patch)
            let dto: NotificationDTO = try await apiClient.send(endpoint, decodingTo: NotificationDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: NotificationDTO) -> AppNotification {
        AppNotification(
            id: dto.id,
            type: AppNotificationType(rawValue: dto.type) ?? .chatMessage,
            payload: dto.payload.mapValues(attributeValue),
            readAt: dto.readAt,
            deliveredAt: dto.deliveredAt,
            createdAt: dto.createdAt
        )
    }

    static func attributeValue(_ scalar: JSONScalar) -> AttributeValue {
        switch scalar {
        case .string(let s): return .string(s)
        case .number(let n): return .number(n)
        case .bool(let b): return .bool(b)
        case .array(let a): return .stringArray(a.map { if case .string(let s) = $0 { return s } else { return "" } })
        case .null: return .null
        }
    }
}
