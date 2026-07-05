/// docs/planning/03-backend-architecture.md §6 specifies an outbox table +
/// Realtime channel per user with push (APNs) fan-out; real APNs
/// credentials aren't available in this environment (backend/src/ports/
/// push_port.ts), so this is a plain poll-based REST read, not a
/// subscription, and delivery is only ever a logging no-op.
public protocol NotificationsRepository: Sendable {
    func fetchNotifications() async throws -> [AppNotification]
    func markRead(id: String) async throws -> AppNotification
}
