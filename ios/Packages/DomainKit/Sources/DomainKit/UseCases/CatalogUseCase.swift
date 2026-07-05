/// Bundles the catalog's three read operations for `Presentation` — like
/// `AuthUseCase`, one cohesive entry point rather than three near-empty
/// pass-through types, since none of the three carry logic beyond the
/// repository call itself.
public protocol CatalogUseCase: Sendable {
    func fetchTree(locale: String) async throws -> [CategoryTreeNode]
    func fetchSchema(categoryId: String, locale: String) async throws -> ComposedSchema
    func fetchOptions(attributeId: String, parentOptionId: String?, locale: String) async throws -> [AttributeOption]
}

public struct DefaultCatalogUseCase: CatalogUseCase {
    private let categoryRepository: CategoryRepository

    public init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    public func fetchTree(locale: String) async throws -> [CategoryTreeNode] {
        try await categoryRepository.fetchTree(locale: locale)
    }

    public func fetchSchema(categoryId: String, locale: String) async throws -> ComposedSchema {
        try await categoryRepository.fetchSchema(categoryId: categoryId, locale: locale)
    }

    public func fetchOptions(attributeId: String, parentOptionId: String?, locale: String) async throws -> [AttributeOption] {
        try await categoryRepository.fetchOptions(attributeId: attributeId, parentOptionId: parentOptionId, locale: locale)
    }
}
