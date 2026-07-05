import Core
import DomainKit
import DynamicForms
import Observation

/// Owns category selection, the schema-driven filter state, and the
/// filtered/paginated results — one cohesive view model for the whole
/// Search tab rather than splitting into several that would just pass the
/// same category id back and forth.
@Observable
@MainActor
final class SearchViewModel {
    private(set) var leafCategories: [CategoryTreeNode] = []
    private(set) var selectedCategory: CategoryTreeNode?
    private(set) var schema: ComposedSchema?
    /// Filterable option/bool fields only — equality filters, rendered via
    /// `DynamicFormView` (the same registry the create-listing form uses).
    /// Filterable *number* fields need a min/max range, which isn't part of
    /// `DynamicFormState`'s single-value model, so they're handled separately
    /// via `numberFilterFields`/`rangeValues`.
    private(set) var equalityFormState: DynamicFormState?
    var rangeValues: [String: AttributeRangeFilter] = [:]

    private(set) var results: [Listing] = []
    private(set) var isLoadingCategories = false
    private(set) var isLoadingSchema = false
    private(set) var isLoadingResults = false
    private(set) var hasMoreResults = false
    private(set) var errorMessage: String?
    private var nextCursor: String?

    private let catalogUseCase: CatalogUseCase
    private let listingUseCase: ListingUseCase

    init(catalogUseCase: CatalogUseCase = Container.shared.catalogUseCase(), listingUseCase: ListingUseCase = Container.shared.listingUseCase()) {
        self.catalogUseCase = catalogUseCase
        self.listingUseCase = listingUseCase
    }

    func loadCategories(locale: String = "en") async {
        isLoadingCategories = true
        errorMessage = nil
        defer { isLoadingCategories = false }
        do {
            let tree = try await catalogUseCase.fetchTree(locale: locale)
            leafCategories = Self.flattenLeaves(tree)
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func selectCategory(_ node: CategoryTreeNode, locale: String = "en") async {
        selectedCategory = node
        schema = nil
        equalityFormState = nil
        rangeValues = [:]
        results = []
        isLoadingSchema = true
        errorMessage = nil
        defer { isLoadingSchema = false }
        do {
            let schema = try await catalogUseCase.fetchSchema(categoryId: node.id, locale: locale)
            self.schema = schema
            equalityFormState = DynamicFormState(schema: Self.equalityOnlySchema(from: schema))
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
        await runSearch()
    }

    func clearSelection() {
        selectedCategory = nil
        schema = nil
        equalityFormState = nil
        rangeValues = [:]
        results = []
        errorMessage = nil
    }

    var numberFilterFields: [SchemaField] {
        (schema?.allFields ?? []).filter { $0.isFilterable && $0.dataType == .number }
    }

    func runSearch() async {
        guard let category = selectedCategory else { return }
        nextCursor = nil
        await fetchResultsPage(categoryId: category.id, reset: true)
    }

    func loadMoreResults() async {
        guard let category = selectedCategory, hasMoreResults, !isLoadingResults else { return }
        await fetchResultsPage(categoryId: category.id, reset: false)
    }

    private func fetchResultsPage(categoryId: String, reset: Bool) async {
        isLoadingResults = true
        errorMessage = nil
        defer { isLoadingResults = false }
        do {
            let page = try await listingUseCase.fetchListings(filters: currentFilters(categoryId: categoryId, cursor: reset ? nil : nextCursor))
            results = reset ? page.items : results + page.items
            nextCursor = page.nextCursor
            hasMoreResults = page.hasMore
        } catch {
            errorMessage = (error as? DomainError)?.errorDescription ?? "\(error)"
        }
    }

    func currentFilters(categoryId: String, cursor: String? = nil) -> ListingFilters {
        var attributes: [String: AttributeFilterValue] = [:]
        if let equalityFormState {
            for (key, value) in equalityFormState.values {
                attributes[key] = .equals(value)
            }
        }
        for (key, range) in rangeValues where range.gte != nil || range.lte != nil || range.gt != nil || range.lt != nil {
            attributes[key] = .range(range)
        }
        return ListingFilters(categoryId: categoryId, attributes: attributes, cursor: cursor)
    }

    private static func flattenLeaves(_ nodes: [CategoryTreeNode]) -> [CategoryTreeNode] {
        nodes.flatMap { node in node.isLeaf ? [node] : flattenLeaves(node.children) }
    }

    private static func equalityOnlySchema(from schema: ComposedSchema) -> ComposedSchema {
        ComposedSchema(
            schemaVersion: schema.schemaVersion,
            category: schema.category,
            groups: schema.groups.compactMap { group in
                let fields = group.fields.filter { $0.isFilterable && $0.dataType != .number }
                return fields.isEmpty ? nil : SchemaGroup(id: group.id, name: group.name, isCollapsible: group.isCollapsible, fields: fields)
            }
        )
    }
}
