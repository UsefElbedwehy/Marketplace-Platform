/// Decodes `contract/openapi/v1/openapi.yaml`'s `CategoryTreeNode`/
/// `ComposedSchema`/`SchemaGroup`/`SchemaField`/`AttributeOption`/
/// `AttributeDependency` field-for-field. `CategoryRepositoryImpl` maps these
/// onto `DomainKit`'s entities — the only place this translation happens.
struct CategoryTreeNodeDTO: Decodable {
    let id: String
    let slug: String
    let name: String
    let icon: String?
    let sortOrder: Int
    let isLeaf: Bool
    let children: [CategoryTreeNodeDTO]
}

struct AttributeOptionDTO: Decodable {
    let id: String
    let value: String
    let label: String
    let parentOptionId: String?
}

struct AttributeDependencyDTO: Decodable {
    struct Condition: Decodable {
        let equals: JSONScalar?
    }
    let field: String
    let rule: String
    let condition: Condition
}

struct SchemaFieldDTO: Decodable {
    let id: String
    let key: String
    let label: String
    let dataType: String
    let inputType: String
    let required: Bool
    let filterable: Bool
    let searchable: Bool
    let sortOrder: Int
    let unit: String?
    let validation: [String: JSONScalar]
    let options: [AttributeOptionDTO]
    let dependsOn: [AttributeDependencyDTO]
}

struct SchemaGroupDTO: Decodable {
    let id: String
    let name: String
    let collapsible: Bool
    let fields: [SchemaFieldDTO]
}

struct ComposedSchemaDTO: Decodable {
    struct CategoryRef: Decodable {
        let id: String
        let slug: String
        let name: String
        let path: [String]
    }
    let schemaVersion: Int
    let category: CategoryRef
    let groups: [SchemaGroupDTO]
}
