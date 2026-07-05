import Core
import DomainKit
import Networking

/// Fulfils `DomainKit.SellerProfileRepository` — the only place
/// `SellerProfileDTO` translates to/from `DomainKit.SellerProfile`.
public struct SellerProfileRepositoryImpl: SellerProfileRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchSellerProfile(id: String) async throws -> SellerProfile {
        do {
            // Authenticated, not anonymous: the endpoint itself is public,
            // but attaching the caller's token gives `fetchActiveConfig` a
            // tenant claim to resolve against — without one, an anon
            // request's config lookup can non-deterministically resolve to
            // a *different* tenant's config bundle (see `config.bundle`'s
            // RLS policy), which would apply the wrong client's module
            // flags to this response.
            let endpoint = APIEndpoint(path: "/v1/profiles/\(id)")
            let dto: SellerProfileDTO = try await apiClient.send(endpoint, decodingTo: SellerProfileDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: SellerProfileDTO) -> SellerProfile {
        SellerProfile(
            id: dto.id, displayName: dto.displayName, avatarUrl: dto.avatarUrl, bio: dto.bio,
            memberSince: dto.memberSince, ratingCount: dto.ratingCount, ratingAverage: dto.ratingAverage,
            publishedListingCount: dto.publishedListingCount
        )
    }
}
