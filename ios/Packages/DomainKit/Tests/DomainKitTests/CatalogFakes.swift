@testable import DomainKit

struct StubCategoryRepository: CategoryRepository {
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

actor StubListingRepository: ListingRepository {
    var created: CreateListingDraft?
    var listing: Listing
    var page: Page<Listing>
    var error: Error?

    init(listing: Listing = .fixture(), page: Page<Listing> = Page(items: [], nextCursor: nil, hasMore: false), error: Error? = nil) {
        self.listing = listing
        self.page = page
        self.error = error
    }

    func createListing(_ draft: CreateListingDraft) async throws -> Listing {
        if let error { throw error }
        created = draft
        return listing
    }

    func fetchListing(id: String) async throws -> Listing {
        if let error { throw error }
        return listing
    }

    func fetchListings(filters: ListingFilters) async throws -> Page<Listing> {
        if let error { throw error }
        return page
    }

    func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing {
        if let error { throw error }
        return Listing(
            id: listing.id, ownerId: listing.ownerId, categoryId: listing.categoryId, title: listing.title, description: listing.description,
            price: listing.price, currency: listing.currency, status: status, attributesIndex: listing.attributesIndex,
            createdAt: listing.createdAt
        )
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
