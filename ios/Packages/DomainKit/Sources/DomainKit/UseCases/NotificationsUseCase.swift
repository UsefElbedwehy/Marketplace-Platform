public protocol NotificationsUseCase: Sendable {
    func fetchNotifications() async throws -> [AppNotification]
    func markRead(id: String) async throws -> AppNotification
}

public struct DefaultNotificationsUseCase: NotificationsUseCase {
    private let notificationsRepository: NotificationsRepository

    public init(notificationsRepository: NotificationsRepository) {
        self.notificationsRepository = notificationsRepository
    }

    public func fetchNotifications() async throws -> [AppNotification] {
        try await notificationsRepository.fetchNotifications()
    }

    public func markRead(id: String) async throws -> AppNotification {
        try await notificationsRepository.markRead(id: id)
    }
}
