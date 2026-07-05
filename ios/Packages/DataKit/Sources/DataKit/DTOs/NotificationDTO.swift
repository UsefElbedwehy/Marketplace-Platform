/// Decodes the contract's `Notification`. `NotificationsRepositoryImpl` maps
/// this onto `DomainKit.AppNotification`.
struct NotificationDTO: Decodable {
    let id: String
    let type: String
    let payload: [String: JSONScalar]
    let readAt: String?
    let deliveredAt: String?
    let createdAt: String
}
