import Core
import DomainKit
import Foundation
import Networking

/// Fulfils `DomainKit.ListingRepository` ⭐ — the only place `ListingDTO`/
/// `CreateListingRequestDTO` are translated to/from `DomainKit.Listing`/
/// `CreateListingDraft`, and `AttributeValue` <-> `JSONScalar`.
public struct ListingRepositoryImpl: ListingRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func createListing(_ draft: CreateListingDraft) async throws -> Listing {
        let body = CreateListingRequestDTO(
            categoryId: draft.categoryId,
            title: draft.title,
            description: draft.description,
            price: draft.price,
            currency: draft.currency,
            attributes: draft.attributes.mapValues(Self.scalar)
        )
        do {
            let endpoint = try APIEndpoint.encoding(body, path: "/v1/listings", method: .post)
            let dto: ListingDTO = try await apiClient.send(endpoint, decodingTo: ListingDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func fetchListing(id: String) async throws -> Listing {
        do {
            let endpoint = APIEndpoint(path: "/v1/listings/\(id)", requiresAuth: false)
            let dto: ListingDTO = try await apiClient.send(endpoint, decodingTo: ListingDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func fetchListings(filters: ListingFilters) async throws -> Page<Listing> {
        var queryItems: [URLQueryItem] = []
        if let categoryId = filters.categoryId { queryItems.append(URLQueryItem(name: "category", value: categoryId)) }
        if let status = filters.status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
        if filters.mine { queryItems.append(URLQueryItem(name: "owner", value: "me")) }
        if let cursor = filters.cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }
        queryItems.append(URLQueryItem(name: "limit", value: String(filters.limit)))
        if !filters.attributes.isEmpty, let filtersJSON = Self.encodeFilters(filters.attributes) {
            queryItems.append(URLQueryItem(name: "filters", value: filtersJSON))
        }

        do {
            // Auth is needed whenever the caller wants anything beyond the
            // public "published" default — "my listings" (any status) or a
            // moderator's explicit status filter (e.g. pending_review).
            let endpoint = APIEndpoint(path: "/v1/listings", queryItems: queryItems, requiresAuth: filters.mine || filters.status != nil)
            let (dtos, page) = try await apiClient.sendCollection(endpoint, decodingItemsTo: ListingDTO.self)
            return Page(items: dtos.map(Self.map), nextCursor: page.nextCursor, hasMore: page.hasMore)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing {
        do {
            let endpoint = try APIEndpoint.encoding(
                UpdateListingStatusRequestDTO(status: status.rawValue),
                path: "/v1/listings/\(listingId)",
                method: .patch
            )
            let dto: ListingDTO = try await apiClient.send(endpoint, decodingTo: ListingDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: ListingDTO) -> Listing {
        Listing(
            id: dto.id, ownerId: dto.ownerId, categoryId: dto.categoryId, title: dto.title, description: dto.description,
            price: dto.price, currency: dto.currency, status: ListingStatus(rawValue: dto.status) ?? .draft,
            attributesIndex: dto.attributesIndex.mapValues(attributeValue), createdAt: dto.createdAt
        )
    }

    static func attributeValue(_ scalar: JSONScalar) -> AttributeValue {
        switch scalar {
        case .string(let s): return .string(s)
        case .number(let n): return .number(n)
        case .bool(let b): return .bool(b)
        case .array(let a): return .stringArray(a.map { if case .string(let s) = $0 { return s } else { return "" } })
        case .null: return .null
        }
    }

    static func scalar(_ value: AttributeValue) -> JSONScalar {
        switch value {
        case .string(let s): return .string(s)
        case .number(let n): return .number(n)
        case .bool(let b): return .bool(b)
        case .stringArray(let a): return .array(a.map { .string($0) })
        case .null: return .null
        }
    }

    /// `filters=<JSON>` — equality (`{"brand":"bmw"}`) or range
    /// (`{"mileage":{"lt":100000}}`) per key (docs/planning/05 §7).
    static func encodeFilters(_ attributes: [String: AttributeFilterValue]) -> String? {
        var json: [String: Any] = [:]
        for (key, value) in attributes {
            switch value {
            case .equals(let attrValue):
                json[key] = jsonAny(scalar(attrValue))
            case .range(let range):
                var rangeJSON: [String: Double] = [:]
                if let gte = range.gte { rangeJSON["gte"] = gte }
                if let lte = range.lte { rangeJSON["lte"] = lte }
                if let gt = range.gt { rangeJSON["gt"] = gt }
                if let lt = range.lt { rangeJSON["lt"] = lt }
                json[key] = rangeJSON
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func jsonAny(_ scalar: JSONScalar) -> Any {
        switch scalar {
        case .string(let s): return s
        case .number(let n): return n
        case .bool(let b): return b
        case .array(let a): return a.map(jsonAny)
        case .null: return NSNull()
        }
    }
}
