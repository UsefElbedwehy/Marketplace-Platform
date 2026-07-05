import Core
import DomainKit
import Networking

/// Fulfils `DomainKit.FavoritesRepository` — the only place `FavoriteDTO`
/// translates to/from `DomainKit.Favorite`.
public struct FavoritesRepositoryImpl: FavoritesRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchFavorites() async throws -> [Favorite] {
        do {
            let endpoint = APIEndpoint(path: "/v1/favorites")
            let dtos: [FavoriteDTO] = try await apiClient.send(endpoint, decodingTo: [FavoriteDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func addFavorite(listingId: String) async throws -> Favorite {
        do {
            let endpoint = APIEndpoint(path: "/v1/favorites/\(listingId)", method: .put)
            let dto: FavoriteDTO = try await apiClient.send(endpoint, decodingTo: FavoriteDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func removeFavorite(listingId: String) async throws {
        do {
            let endpoint = APIEndpoint(path: "/v1/favorites/\(listingId)", method: .delete)
            try await apiClient.sendNoContent(endpoint)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: FavoriteDTO) -> Favorite {
        Favorite(id: dto.id, listingId: dto.listingId, createdAt: dto.createdAt)
    }
}
