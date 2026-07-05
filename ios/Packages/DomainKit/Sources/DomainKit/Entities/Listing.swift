/// Mirrors `contract/openapi/v1/openapi.yaml`'s `Listing` — status is the
/// same state machine `backend/src/listing_service.ts` enforces
/// (`draft → pending_review → published/rejected`, `published → archived/sold`, …).
public enum ListingStatus: String, Equatable, Sendable, CaseIterable {
    case draft, pendingReview = "pending_review", published, rejected, archived, sold
}

public struct Listing: Equatable, Sendable, Identifiable {
    public let id: String
    /// The seller — added in Phase 6 to drive "message seller" (`Features/
    /// Chat`) and "view seller profile" (`SellerProfile`) affordances.
    public let ownerId: String
    public let categoryId: String
    public let title: String
    public let description: String?
    public let price: Double?
    public let currency: String?
    public let status: ListingStatus
    /// Keyed by attribute `key` — the client projects this against the
    /// category's `ComposedSchema` for labels/units (ADR-0003).
    public let attributesIndex: [String: AttributeValue]
    public let createdAt: String

    public init(
        id: String, ownerId: String, categoryId: String, title: String, description: String?, price: Double?,
        currency: String?, status: ListingStatus, attributesIndex: [String: AttributeValue], createdAt: String
    ) {
        self.id = id
        self.ownerId = ownerId
        self.categoryId = categoryId
        self.title = title
        self.description = description
        self.price = price
        self.currency = currency
        self.status = status
        self.attributesIndex = attributesIndex
        self.createdAt = createdAt
    }
}

/// `attributes_index` is heterogeneous JSON (a number for `mileage`, a string
/// for `brand`, a bool for `furnished`, an array for `option_multi`) — this
/// is the minimal Sendable/Equatable sum type that lets `DataKit` decode it
/// generically and `Features/Listings` render it without re-parsing raw JSON.
public enum AttributeValue: Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case stringArray([String])
    case null

    public var displayString: String {
        switch self {
        case .string(let s): return s
        case .number(let n): return n.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(n)) : String(n)
        case .bool(let b): return b ? "Yes" : "No"
        case .stringArray(let arr): return arr.joined(separator: ", ")
        case .null: return ""
        }
    }
}

/// What the create-listing form submits — mirrors `CreateListingRequest`.
public struct CreateListingDraft: Equatable, Sendable {
    public let categoryId: String
    public let title: String
    public let description: String?
    public let price: Double?
    public let currency: String?
    public let attributes: [String: AttributeValue]

    public init(categoryId: String, title: String, description: String?, price: Double?, currency: String?, attributes: [String: AttributeValue]) {
        self.categoryId = categoryId
        self.title = title
        self.description = description
        self.price = price
        self.currency = currency
        self.attributes = attributes
    }
}

public struct Page<Item: Equatable & Sendable>: Equatable, Sendable {
    public let items: [Item]
    public let nextCursor: String?
    public let hasMore: Bool

    public init(items: [Item], nextCursor: String?, hasMore: Bool) {
        self.items = items
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}

public struct AttributeRangeFilter: Equatable, Sendable {
    public var gte: Double?
    public var lte: Double?
    public var gt: Double?
    public var lt: Double?

    public init(gte: Double? = nil, lte: Double? = nil, gt: Double? = nil, lt: Double? = nil) {
        self.gte = gte
        self.lte = lte
        self.gt = gt
        self.lt = lt
    }
}

public enum AttributeFilterValue: Equatable, Sendable {
    case equals(AttributeValue)
    case range(AttributeRangeFilter)
}

public struct ListingFilters: Equatable, Sendable {
    public var categoryId: String?
    public var status: ListingStatus?
    /// `owner=me` on the contract — the only supported value is "the caller's
    /// own sub", resolved server-side from the bearer token; there's no way
    /// to filter by an arbitrary other user's id via this endpoint.
    public var mine: Bool
    public var attributes: [String: AttributeFilterValue]
    public var cursor: String?
    public var limit: Int

    public init(
        categoryId: String? = nil, status: ListingStatus? = nil, mine: Bool = false,
        attributes: [String: AttributeFilterValue] = [:], cursor: String? = nil, limit: Int = 20
    ) {
        self.categoryId = categoryId
        self.status = status
        self.mine = mine
        self.attributes = attributes
        self.cursor = cursor
        self.limit = limit
    }
}
