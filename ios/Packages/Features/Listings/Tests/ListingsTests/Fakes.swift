import DomainKit
@testable import Listings

struct StubCatalogUseCase: CatalogUseCase {
    var tree: [CategoryTreeNode] = []
    var schema: ComposedSchema = .fixture()
    var options: [AttributeOption] = []
    var error: Error?

    func fetchTree(locale: String) async throws -> [CategoryTreeNode] {
        if let error { throw error }
        return tree
    }

    func fetchSchema(categoryId: String, locale: String) async throws -> ComposedSchema {
        if let error { throw error }
        return schema
    }

    func fetchOptions(attributeId: String, parentOptionId: String?, locale: String) async throws -> [AttributeOption] {
        if let error { throw error }
        return options
    }
}

actor StubListingUseCase: ListingUseCase {
    var createdDraft: CreateListingDraft?
    var createResult: Result<Listing, Error>
    var listing: Listing
    var page: Page<Listing>
    var fetchListingsError: Error?
    var updateStatusCalls: [(id: String, status: ListingStatus)] = []

    init(
        listing: Listing = .fixture(), page: Page<Listing> = Page(items: [], nextCursor: nil, hasMore: false),
        createResult: Result<Listing, Error>? = nil, fetchListingsError: Error? = nil
    ) {
        self.listing = listing
        self.page = page
        self.createResult = createResult ?? .success(listing)
        self.fetchListingsError = fetchListingsError
    }

    func createListing(_ draft: CreateListingDraft) async throws -> Listing {
        createdDraft = draft
        return try createResult.get()
    }

    func fetchListing(id: String) async throws -> Listing {
        listing
    }

    func fetchListings(filters: ListingFilters) async throws -> Page<Listing> {
        if let fetchListingsError { throw fetchListingsError }
        return page
    }

    func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing {
        updateStatusCalls.append((listingId, status))
        return Listing(
            id: listing.id, ownerId: listing.ownerId, categoryId: listing.categoryId, title: listing.title, description: listing.description,
            price: listing.price, currency: listing.currency, status: status, attributesIndex: listing.attributesIndex,
            createdAt: listing.createdAt
        )
    }
}

/// A moderator-queue-aware stub: returns different pages for the "mine"
/// filter vs. an explicit-status filter, since `MyListingsViewModel` fetches
/// both concurrently.
actor RoleAwareStubListingUseCase: ListingUseCase {
    let minePage: Page<Listing>
    let queuePage: Page<Listing>
    var error: Error?

    init(minePage: Page<Listing>, queuePage: Page<Listing>) {
        self.minePage = minePage
        self.queuePage = queuePage
    }

    func createListing(_ draft: CreateListingDraft) async throws -> Listing { .fixture() }
    func fetchListing(id: String) async throws -> Listing { .fixture() }

    func fetchListings(filters: ListingFilters) async throws -> Page<Listing> {
        if let error { throw error }
        return filters.mine ? minePage : queuePage
    }

    func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing {
        Listing(id: listingId, ownerId: "seller-1", categoryId: "cat-1", title: "t", description: nil, price: nil, currency: nil, status: status, attributesIndex: [:], createdAt: "2026-01-01T00:00:00Z")
    }
}

struct StubAuthUseCase: AuthUseCase {
    var session: AuthSession?

    func currentSession() async -> AuthSession? { session }
    func signIn(as identity: DevIdentity) async throws -> AuthSession { .fixture() }
    func signOut() async {}
}

extension AuthSession {
    static func fixture(appRole: String = "seller") -> AuthSession {
        AuthSession(accessToken: "token", sub: "sub-1", tenantId: "tenant-1", appRole: appRole, displayName: "Dev User")
    }
}

extension ComposedSchema {
    static func fixture(schemaVersion: Int = 1) -> ComposedSchema {
        ComposedSchema(
            schemaVersion: schemaVersion,
            category: .init(id: "cat-1", slug: "cars", name: "Cars", path: ["Vehicles", "Cars"]),
            groups: [
                SchemaGroup(id: "group-1", name: "Details", isCollapsible: false, fields: [
                    SchemaField(
                        id: "attr-brand", key: "brand", label: "Brand", dataType: .option, inputType: .dropdown,
                        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 0, unit: nil,
                        minValue: nil, maxValue: nil, maxLength: nil,
                        options: [AttributeOption(id: "opt-bmw", value: "bmw", label: "BMW", parentOptionId: nil)],
                        dependsOn: []
                    ),
                ]),
            ]
        )
    }
}

extension Listing {
    static func fixture(id: String = "listing-1", status: ListingStatus = .draft) -> Listing {
        Listing(
            id: id, ownerId: "seller-1", categoryId: "cat-1", title: "2019 BMW", description: nil, price: 85000, currency: "SAR",
            status: status, attributesIndex: ["brand": .string("bmw")], createdAt: "2026-01-01T00:00:00Z"
        )
    }
}

extension CategoryTreeNode {
    static func fixture(id: String = "c1", isLeaf: Bool = true) -> CategoryTreeNode {
        CategoryTreeNode(id: id, slug: "cars", name: "Cars", icon: nil, sortOrder: 0, isLeaf: isLeaf, children: [])
    }
}
