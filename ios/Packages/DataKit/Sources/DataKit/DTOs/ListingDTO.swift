/// Decodes the contract's `Listing` / `PaginationMeta`. `ListingRepositoryImpl`
/// maps these onto `DomainKit.Listing`/`Page<Listing>`.
struct ListingDTO: Decodable {
    let id: String
    let ownerId: String
    let categoryId: String
    let title: String
    let description: String?
    let price: Double?
    let currency: String?
    let status: String
    let attributesIndex: [String: JSONScalar]
    let createdAt: String
}

struct PaginationMetaDTO: Decodable {
    let nextCursor: String?
    let hasMore: Bool
}

struct ListingsPageDTO: Decodable {
    let data: [ListingDTO]
    let page: PaginationMetaDTO
}

/// What `POST /v1/listings` accepts — `CreateListingRequest` in the contract.
struct CreateListingRequestDTO: Encodable {
    let categoryId: String
    let title: String
    let description: String?
    let price: Double?
    let currency: String?
    let attributes: [String: JSONScalar]
}

struct UpdateListingStatusRequestDTO: Encodable {
    let status: String
}
