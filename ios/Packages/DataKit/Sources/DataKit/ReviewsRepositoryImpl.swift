import Core
import DomainKit
import Foundation
import Networking

/// Fulfils `DomainKit.ReviewsRepository` — the only place `ReviewDTO`
/// translates to/from `DomainKit.Review`.
public struct ReviewsRepositoryImpl: ReviewsRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchReviews(sellerId: String) async throws -> [Review] {
        do {
            // Authenticated for the same reason as `SellerProfileRepositoryImpl.
            // fetchSellerProfile` — an anon request's config lookup can
            // resolve to the wrong tenant's module flags, which would
            // incorrectly 404 this endpoint as feature-disabled.
            let endpoint = APIEndpoint(path: "/v1/reviews", queryItems: [URLQueryItem(name: "sellerId", value: sellerId)])
            let dtos: [ReviewDTO] = try await apiClient.send(endpoint, decodingTo: [ReviewDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func createReview(_ draft: CreateReviewDraft) async throws -> Review {
        do {
            let body = CreateReviewRequestDTO(revieweeId: draft.revieweeId, listingId: draft.listingId, rating: draft.rating, comment: draft.comment)
            let endpoint = try APIEndpoint.encoding(body, path: "/v1/reviews", method: .post)
            let dto: ReviewDTO = try await apiClient.send(endpoint, decodingTo: ReviewDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: ReviewDTO) -> Review {
        Review(
            id: dto.id, reviewerId: dto.reviewerId, reviewerDisplayName: dto.reviewerDisplayName,
            revieweeId: dto.revieweeId, listingId: dto.listingId, rating: dto.rating,
            comment: dto.comment, createdAt: dto.createdAt
        )
    }
}
