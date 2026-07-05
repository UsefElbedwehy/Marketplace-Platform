import Testing
import Core
import Networking
@testable import DataKit
@testable import DomainKit

@Test func notificationsRepositoryFetchesAndMapsThePayload() async throws {
    let dto = NotificationDTO(
        id: "n1", type: "chat_message",
        payload: ["conversationId": .string("c1"), "listingId": .string("l1")],
        readAt: nil, deliveredAt: "2026-01-01T00:00:01Z", createdAt: "2026-01-01T00:00:00Z"
    )
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/notifications", value: [dto])])
    let repo = NotificationsRepositoryImpl(apiClient: client)

    let notifications = try await repo.fetchNotifications()

    #expect(notifications.first?.type == .chatMessage)
    #expect(notifications.first?.payload["conversationId"] == .string("c1"))
    #expect(notifications.first?.deliveredAt == "2026-01-01T00:00:01Z")
}

@Test func notificationsRepositoryMarksRead() async throws {
    let dto = NotificationDTO(id: "n1", type: "chat_message", payload: [:], readAt: "2026-01-01T00:01:00Z", deliveredAt: nil, createdAt: "2026-01-01T00:00:00Z")
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/notifications/n1", value: dto)])
    let repo = NotificationsRepositoryImpl(apiClient: client)

    let notification = try await repo.markRead(id: "n1")

    #expect(notification.readAt == "2026-01-01T00:01:00Z")
}

@Test func notificationsRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/notifications", value: nil, error: Boom())])
    let repo = NotificationsRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.fetchNotifications()
    }
}
