import Testing
import Core
import Networking
@testable import DataKit
@testable import DomainKit

@Test func favoritesRepositoryAddsAFavorite() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/favorites/l1", value: FavoriteDTO(id: "f1", listingId: "l1", createdAt: "2026-01-01T00:00:00Z"))])
    let repo = FavoritesRepositoryImpl(apiClient: client)

    let favorite = try await repo.addFavorite(listingId: "l1")

    #expect(favorite.listingId == "l1")
}

@Test func favoritesRepositoryRemovesAFavoriteWithNoContentResponse() async throws {
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/favorites/l1", value: nil)])
    let repo = FavoritesRepositoryImpl(apiClient: client)

    try await repo.removeFavorite(listingId: "l1")

    #expect(client.lastPath == "/v1/favorites/l1")
}

@Test func favoritesRepositoryFetchesTheList() async throws {
    let client = RoutedFakeAPIClient(routes: [
        .init(pathContains: "/v1/favorites", value: [FavoriteDTO(id: "f1", listingId: "l1", createdAt: "2026-01-01T00:00:00Z")]),
    ])
    let repo = FavoritesRepositoryImpl(apiClient: client)

    let favorites = try await repo.fetchFavorites()

    #expect(favorites.map(\.listingId) == ["l1"])
}

@Test func favoritesRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/favorites/l1", value: nil, error: Boom())])
    let repo = FavoritesRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.addFavorite(listingId: "l1")
    }
}
