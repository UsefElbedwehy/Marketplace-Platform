import Testing
import Core
import Networking
@testable import DataKit
@testable import DomainKit

@Test func categoryRepositoryMapsTheTreeRecursively() async throws {
    let child = CategoryTreeNodeDTO(id: "c2", slug: "sedans", name: "Sedans", icon: nil, sortOrder: 0, isLeaf: true, children: [])
    let root = CategoryTreeNodeDTO(id: "c1", slug: "cars", name: "Cars", icon: "car", sortOrder: 0, isLeaf: false, children: [child])
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/categories/tree", value: [root])])
    let repo = CategoryRepositoryImpl(apiClient: client)

    let tree = try await repo.fetchTree(locale: "en")

    #expect(tree.first?.id == "c1")
    #expect(tree.first?.children.first?.id == "c2")
    #expect(tree.first?.isLeaf == false)
}

@Test func categoryRepositoryMapsAComposedSchemaIncludingValidationAndDependencies() async throws {
    let brandOption = AttributeOptionDTO(id: "opt-bmw", value: "bmw", label: "BMW", parentOptionId: nil)
    let modelField = SchemaFieldDTO(
        id: "attr-model", key: "model", label: "Model", dataType: "option", inputType: "dropdown",
        required: true, filterable: true, searchable: false, sortOrder: 1, unit: nil,
        validation: [:], options: [AttributeOptionDTO(id: "opt-x5", value: "x5", label: "X5", parentOptionId: "opt-bmw")],
        dependsOn: [AttributeDependencyDTO(field: "brand", rule: "options_filtered_by", condition: .init(equals: nil))]
    )
    let mileageField = SchemaFieldDTO(
        id: "attr-mileage", key: "mileage", label: "Mileage", dataType: "number", inputType: "stepper",
        required: false, filterable: true, searchable: false, sortOrder: 2, unit: "km",
        validation: ["min": .number(0), "max": .number(2_000_000)], options: [], dependsOn: []
    )
    let group = SchemaGroupDTO(id: "g1", name: "Details", collapsible: false, fields: [modelField, mileageField])
    let schemaDTO = ComposedSchemaDTO(schemaVersion: 5, category: .init(id: "cat-1", slug: "cars", name: "Cars", path: ["Vehicles", "Cars"]), groups: [group])
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/schema", value: schemaDTO)])
    let repo = CategoryRepositoryImpl(apiClient: client)

    let schema = try await repo.fetchSchema(categoryId: "cat-1", locale: "en")

    #expect(schema.schemaVersion == 5)
    let mileage = schema.allFields.first { $0.key == "mileage" }
    #expect(mileage?.minValue == 0)
    #expect(mileage?.maxValue == 2_000_000)
    let model = schema.allFields.first { $0.key == "model" }
    #expect(model?.dependsOn.first?.rule == .optionsFilteredBy)
    #expect(model?.options.first?.parentOptionId == "opt-bmw")
    _ = brandOption
}

@Test func categoryRepositoryFetchesDependentOptionsWithAParentQueryParam() async throws {
    let client = RoutedFakeAPIClient(routes: [
        .init(pathContains: "/options", value: [AttributeOptionDTO(id: "o1", value: "x5", label: "X5", parentOptionId: "opt-bmw")]),
    ])
    let repo = CategoryRepositoryImpl(apiClient: client)

    let options = try await repo.fetchOptions(attributeId: "attr-model", parentOptionId: "opt-bmw", locale: "en")

    #expect(options.first?.value == "x5")
}

@Test func categoryRepositoryMapsAnUnexpectedFailureToDomainNetworkError() async {
    struct Boom: Error {}
    let client = RoutedFakeAPIClient(routes: [.init(pathContains: "/v1/categories/tree", value: nil, error: Boom())])
    let repo = CategoryRepositoryImpl(apiClient: client)

    await #expect(throws: DomainError.network) {
        try await repo.fetchTree(locale: "en")
    }
}
