import Testing
@testable import DomainKit

@Test func catalogUseCaseFetchesTheTree() async throws {
    let node = CategoryTreeNode(id: "c1", slug: "vehicles", name: "Vehicles", icon: nil, sortOrder: 0, isLeaf: false, children: [])
    let useCase = DefaultCatalogUseCase(categoryRepository: StubCategoryRepository(tree: [node]))

    let tree = try await useCase.fetchTree(locale: "en")

    #expect(tree == [node])
}

@Test func catalogUseCaseFetchesTheSchema() async throws {
    let useCase = DefaultCatalogUseCase(categoryRepository: StubCategoryRepository(schema: .fixture(schemaVersion: 3)))

    let schema = try await useCase.fetchSchema(categoryId: "cat-1", locale: "en")

    #expect(schema.schemaVersion == 3)
}

@Test func catalogUseCaseFetchesDependentOptions() async throws {
    let option = AttributeOption(id: "o1", value: "x5", label: "X5", parentOptionId: "opt-bmw")
    let useCase = DefaultCatalogUseCase(categoryRepository: StubCategoryRepository(options: [option]))

    let options = try await useCase.fetchOptions(attributeId: "attr-model", parentOptionId: "opt-bmw", locale: "en")

    #expect(options == [option])
}

@Test func catalogUseCasePropagatesFailure() async {
    struct Boom: Error {}
    let useCase = DefaultCatalogUseCase(categoryRepository: StubCategoryRepository(error: Boom()))

    await #expect(throws: Boom.self) {
        try await useCase.fetchTree(locale: "en")
    }
}

@Test func composedSchemaFlattensAllFieldsAcrossGroups() {
    let schema = ComposedSchema(
        schemaVersion: 1,
        category: .init(id: "c", slug: "s", name: "n", path: []),
        groups: [
            SchemaGroup(id: "g1", name: "A", isCollapsible: false, fields: [
                SchemaField(id: "a1", key: "k1", label: "L1", dataType: .text, inputType: .textfield, isRequired: false, isFilterable: false, isSearchable: false, sortOrder: 0, unit: nil, minValue: nil, maxValue: nil, maxLength: nil, options: [], dependsOn: []),
            ]),
            SchemaGroup(id: "g2", name: "B", isCollapsible: false, fields: [
                SchemaField(id: "a2", key: "k2", label: "L2", dataType: .text, inputType: .textfield, isRequired: false, isFilterable: false, isSearchable: false, sortOrder: 0, unit: nil, minValue: nil, maxValue: nil, maxLength: nil, options: [], dependsOn: []),
            ]),
        ]
    )

    #expect(schema.allFields.map(\.key) == ["k1", "k2"])
}
