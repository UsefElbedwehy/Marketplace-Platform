/// docs/planning/03-backend-architecture.md §6's outbox notification — an
/// in-app list read via poll (no Realtime, see `NotificationsRepository`'s
/// doc comment). Named `AppNotification`, not `Notification`, to avoid
/// colliding with Foundation's `Notification`.
public enum AppNotificationType: String, Equatable, Sendable {
    case chatMessage = "chat_message"
    case listingFavorited = "listing_favorited"
    case reviewReceived = "review_received"
}

public struct AppNotification: Identifiable, Equatable, Sendable {
    public let id: String
    public let type: AppNotificationType
    /// Shape depends on `type` — e.g. a `.chatMessage` notification's
    /// payload has `conversationId`/`messageId`/`listingId` string values.
    public let payload: [String: AttributeValue]
    public let readAt: String?
    /// When the push provider port attempted delivery — not a guarantee of
    /// real device delivery (backend/src/ports/push_port.ts).
    public let deliveredAt: String?
    public let createdAt: String

    public init(id: String, type: AppNotificationType, payload: [String: AttributeValue], readAt: String?, deliveredAt: String?, createdAt: String) {
        self.id = id
        self.type = type
        self.payload = payload
        self.readAt = readAt
        self.deliveredAt = deliveredAt
        self.createdAt = createdAt
    }
}
