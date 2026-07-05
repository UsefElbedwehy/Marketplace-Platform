/// Fulfilled in `DataKit` by wrapping `Networking`'s catalog endpoints
/// (`GET /v1/categories/tree`, `GET /v1/categories/{id}/schema`,
/// `GET /v1/attributes/{id}/options`) — the Dynamic Category & Attribute
/// Engine's read contract ⭐.
public protocol CategoryRepository: Sendable {
    func fetchTree(locale: String) async throws -> [CategoryTreeNode]
    func fetchSchema(categoryId: String, locale: String) async throws -> ComposedSchema
    func fetchOptions(attributeId: String, parentOptionId: String?, locale: String) async throws -> [AttributeOption]
}
