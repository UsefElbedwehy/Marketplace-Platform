import DomainKit
@testable import Search

struct StubCatalogUseCase: CatalogUseCase {
    var tree: [CategoryTreeNode] = []
    var schema: ComposedSchema = .fixture()
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
        []
    }
}

actor StubListingUseCase: ListingUseCase {
    var page: Page<Listing>
    var capturedFilters: [ListingFilters] = []
    var error: Error?

    init(page: Page<Listing> = Page(items: [], nextCursor: nil, hasMore: false), error: Error? = nil) {
        self.page = page
        self.error = error
    }

    func createListing(_ draft: CreateListingDraft) async throws -> Listing { .fixture() }
    func fetchListing(id: String) async throws -> Listing { .fixture() }

    func fetchListings(filters: ListingFilters) async throws -> Page<Listing> {
        capturedFilters.append(filters)
        if let error { throw error }
        return page
    }

    func updateStatus(listingId: String, status: ListingStatus) async throws -> Listing { .fixture() }
}

extension ComposedSchema {
    /// A Cars-shaped fixture: brand (option, filterable), mileage (number,
    /// filterable), vin (text, not filterable) — enough to prove the
    /// equality/range split.
    static func fixture(schemaVersion: Int = 1) -> ComposedSchema {
        ComposedSchema(
            schemaVersion: schemaVersion,
            category: .init(id: "cat-cars", slug: "cars", name: "Cars", path: ["Vehicles", "Cars"]),
            groups: [
                SchemaGroup(id: "g1", name: "Details", isCollapsible: false, fields: [
                    SchemaField(
                        id: "attr-brand", key: "brand", label: "Brand", dataType: .option, inputType: .dropdown,
                        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 0, unit: nil,
                        minValue: nil, maxValue: nil, maxLength: nil,
                        options: [AttributeOption(id: "opt-bmw", value: "bmw", label: "BMW", parentOptionId: nil)],
                        dependsOn: []
                    ),
                    SchemaField(
                        id: "attr-mileage", key: "mileage", label: "Mileage", dataType: .number, inputType: .stepper,
                        isRequired: false, isFilterable: true, isSearchable: false, sortOrder: 1, unit: "km",
                        minValue: 0, maxValue: 2_000_000, maxLength: nil, options: [], dependsOn: []
                    ),
                    SchemaField(
                        id: "attr-vin", key: "vin", label: "VIN", dataType: .text, inputType: .textfield,
                        isRequired: false, isFilterable: false, isSearchable: false, sortOrder: 2, unit: nil,
                        minValue: nil, maxValue: nil, maxLength: 17, options: [], dependsOn: []
                    ),
                ]),
            ]
        )
    }
}

extension Listing {
    static func fixture(id: String = "l1") -> Listing {
        Listing(
            id: id, ownerId: "seller-1", categoryId: "cat-cars", title: "2019 BMW", description: nil, price: 85000, currency: "SAR",
            status: .published, attributesIndex: ["brand": .string("bmw")], createdAt: "2026-01-01T00:00:00Z"
        )
    }
}

extension CategoryTreeNode {
    static func fixture(id: String = "cat-cars", isLeaf: Bool = true, children: [CategoryTreeNode] = []) -> CategoryTreeNode {
        CategoryTreeNode(id: id, slug: "cars", name: "Cars", icon: nil, sortOrder: 0, isLeaf: isLeaf, children: children)
    }
}
