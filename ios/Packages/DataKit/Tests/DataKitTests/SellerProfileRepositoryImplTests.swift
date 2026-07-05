import Testing
import Core
import Networking
@testable import DataKit
@testable import DomainKit

@Test func sellerProfileRepositoryFetchesAndMapsAProfileWithoutRequiringAuth() async throws {
    let dto = SellerProfileDTO(
        id: "seller-1", displayName: "Dev Seller", avatarUrl: nil, bio: "Selling quality cars.",
        memberSince: "2026-01-01T00:00:00Z", ratingCount: 3, ratingAverage: 4.7, publishedListingCount: 5
    )
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/profiles/seller-1", value: dto)])
    let repo = SellerProfileRepositoryImpl(apiClient: client)

    let profile = try await repo.fetchSellerProfile(id: "seller-1")

    #expect(profile.displayName == "Dev Seller")
    #expect(profile.ratingAverage == 4.7)
    #expect(profile.publishedListingCount == 5)
    #expect(client.lastRequiredAuth == false)
}

@Test func sellerProfileRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/profiles/seller-1", value: nil, error: Boom())])
    let repo = SellerProfileRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.fetchSellerProfile(id: "seller-1")
    }
}
