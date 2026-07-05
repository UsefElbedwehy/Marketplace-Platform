import Core
import DomainKit
import Foundation
import Networking

/// Fulfils `DomainKit.CategoryRepository` — the Dynamic Category & Attribute
/// Engine's read side ⭐. The only place `CategoryTreeNodeDTO`/`ComposedSchemaDTO`/
/// `AttributeOptionDTO` are translated into `DomainKit`'s entities.
public struct CategoryRepositoryImpl: CategoryRepository {
    private let apiClient: APIClient

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchTree(locale: String) async throws -> [CategoryTreeNode] {
        let endpoint = APIEndpoint(path: "/v1/categories/tree", queryItems: [URLQueryItem(name: "locale", value: locale)], requiresAuth: false)
        do {
            let dtos: [CategoryTreeNodeDTO] = try await apiClient.send(endpoint, decodingTo: [CategoryTreeNodeDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func fetchSchema(categoryId: String, locale: String) async throws -> ComposedSchema {
        let endpoint = APIEndpoint(
            path: "/v1/categories/\(categoryId)/schema",
            queryItems: [URLQueryItem(name: "locale", value: locale)],
            requiresAuth: false
        )
        do {
            let dto: ComposedSchemaDTO = try await apiClient.send(endpoint, decodingTo: ComposedSchemaDTO.self)
            return Self.map(dto)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    public func fetchOptions(attributeId: String, parentOptionId: String?, locale: String) async throws -> [AttributeOption] {
        var queryItems = [URLQueryItem(name: "locale", value: locale)]
        if let parentOptionId { queryItems.append(URLQueryItem(name: "parent", value: parentOptionId)) }
        let endpoint = APIEndpoint(path: "/v1/attributes/\(attributeId)/options", queryItems: queryItems, requiresAuth: false)
        do {
            let dtos: [AttributeOptionDTO] = try await apiClient.send(endpoint, decodingTo: [AttributeOptionDTO].self)
            return dtos.map(Self.map)
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.network
        }
    }

    // MARK: - Mapping

    static func map(_ dto: CategoryTreeNodeDTO) -> CategoryTreeNode {
        CategoryTreeNode(
            id: dto.id, slug: dto.slug, name: dto.name, icon: dto.icon,
            sortOrder: dto.sortOrder, isLeaf: dto.isLeaf, children: dto.children.map(map)
        )
    }

    static func map(_ dto: AttributeOptionDTO) -> AttributeOption {
        AttributeOption(id: dto.id, value: dto.value, label: dto.label, parentOptionId: dto.parentOptionId)
    }

    static func map(_ dto: AttributeDependencyDTO) -> AttributeDependency? {
        guard let rule = DependencyRule(rawValue: dto.rule) else { return nil }
        return AttributeDependency(field: dto.field, rule: rule, equals: dto.condition.equals.map(scalarToString))
    }

    static func map(_ dto: SchemaFieldDTO) -> SchemaField {
        SchemaField(
            id: dto.id, key: dto.key, label: dto.label,
            dataType: AttributeDataType(rawValue: dto.dataType) ?? .text,
            inputType: AttributeInputType(rawValue: dto.inputType) ?? .textfield,
            isRequired: dto.required, isFilterable: dto.filterable, isSearchable: dto.searchable,
            sortOrder: dto.sortOrder, unit: dto.unit,
            minValue: numberValue(dto.validation["min"]), maxValue: numberValue(dto.validation["max"]),
            maxLength: numberValue(dto.validation["maxLength"]).map(Int.init),
            options: dto.options.map(map), dependsOn: dto.dependsOn.compactMap(map)
        )
    }

    static func map(_ dto: SchemaGroupDTO) -> SchemaGroup {
        SchemaGroup(id: dto.id, name: dto.name, isCollapsible: dto.collapsible, fields: dto.fields.map(map))
    }

    static func map(_ dto: ComposedSchemaDTO) -> ComposedSchema {
        ComposedSchema(
            schemaVersion: dto.schemaVersion,
            category: .init(id: dto.category.id, slug: dto.category.slug, name: dto.category.name, path: dto.category.path),
            groups: dto.groups.map(map)
        )
    }

    private static func numberValue(_ scalar: JSONScalar?) -> Double? {
        guard case .number(let n) = scalar else { return nil }
        return n
    }

    private static func scalarToString(_ scalar: JSONScalar) -> String {
        switch scalar {
        case .string(let s): return s
        case .number(let n): return n.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(n)) : String(n)
        case .bool(let b): return b ? "true" : "false"
        case .array(let a): return a.map(scalarToString).joined(separator: ",")
        case .null: return ""
        }
    }
}
