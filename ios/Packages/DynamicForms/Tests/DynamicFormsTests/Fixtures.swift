import DomainKit

/// A Cars-shaped schema fixture: brand (dropdown) -> model (dependent
/// dropdown, options_filtered_by brand), year (number, min/max), condition
/// (dropdown with a visible_when-gated "conditionNote" text field), vin
/// (text, maxLength).
enum CarsSchemaFixture {
    static let bmw = AttributeOption(id: "opt-bmw", value: "bmw", label: "BMW", parentOptionId: nil)
    static let audi = AttributeOption(id: "opt-audi", value: "audi", label: "Audi", parentOptionId: nil)
    static let x5 = AttributeOption(id: "opt-x5", value: "x5", label: "X5", parentOptionId: "opt-bmw")
    static let a4 = AttributeOption(id: "opt-a4", value: "a4", label: "A4", parentOptionId: "opt-audi")

    static let brandField = SchemaField(
        id: "attr-brand", key: "brand", label: "Brand", dataType: .option, inputType: .dropdown,
        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 0, unit: nil,
        minValue: nil, maxValue: nil, maxLength: nil, options: [bmw, audi], dependsOn: []
    )

    static let modelField = SchemaField(
        id: "attr-model", key: "model", label: "Model", dataType: .option, inputType: .dropdown,
        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 1, unit: nil,
        minValue: nil, maxValue: nil, maxLength: nil, options: [x5, a4],
        dependsOn: [AttributeDependency(field: "brand", rule: .optionsFilteredBy, equals: nil)]
    )

    static let yearField = SchemaField(
        id: "attr-year", key: "year", label: "Year", dataType: .number, inputType: .stepper,
        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 2, unit: nil,
        minValue: 1970, maxValue: 2027, maxLength: nil, options: [], dependsOn: []
    )

    static let conditionField = SchemaField(
        id: "attr-condition", key: "condition", label: "Condition", dataType: .option, inputType: .dropdown,
        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 3, unit: nil,
        minValue: nil, maxValue: nil, maxLength: nil,
        options: [
            AttributeOption(id: "opt-new", value: "new", label: "New", parentOptionId: nil),
            AttributeOption(id: "opt-used", value: "used", label: "Used", parentOptionId: nil),
        ],
        dependsOn: []
    )

    /// Only relevant when `condition == used` — proves `visible_when`.
    static let conditionNoteField = SchemaField(
        id: "attr-conditionNote", key: "conditionNote", label: "Condition note", dataType: .text, inputType: .textfield,
        isRequired: false, isFilterable: false, isSearchable: false, sortOrder: 4, unit: nil,
        minValue: nil, maxValue: nil, maxLength: nil, options: [],
        dependsOn: [AttributeDependency(field: "condition", rule: .visibleWhen, equals: "used")]
    )

    static let vinField = SchemaField(
        id: "attr-vin", key: "vin", label: "VIN", dataType: .text, inputType: .textfield,
        isRequired: false, isFilterable: false, isSearchable: false, sortOrder: 5, unit: nil,
        minValue: nil, maxValue: nil, maxLength: 17, options: [], dependsOn: []
    )

    static let schema = ComposedSchema(
        schemaVersion: 1,
        category: .init(id: "cat-cars", slug: "cars", name: "Cars", path: ["Vehicles", "Cars"]),
        groups: [
            SchemaGroup(id: "g1", name: "Details", isCollapsible: false, fields: [
                brandField, modelField, yearField, conditionField, conditionNoteField, vinField,
            ]),
        ]
    )
}

/// An Apartments-shaped schema fixture: the structural opposite of Cars —
/// no option/dropdown fields and no dependencies at all, just numbers and
/// booleans (mirrors the real seed data: bedrooms/bathrooms/area/floor as
/// stepper numbers, furnished/parking as switches).
enum ApartmentsSchemaFixture {
    static let bedroomsField = SchemaField(
        id: "attr-bedrooms", key: "bedrooms", label: "Bedrooms", dataType: .number, inputType: .stepper,
        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 0, unit: nil,
        minValue: 0, maxValue: 20, maxLength: nil, options: [], dependsOn: []
    )

    static let areaField = SchemaField(
        id: "attr-area", key: "area", label: "Area", dataType: .number, inputType: .stepper,
        isRequired: true, isFilterable: true, isSearchable: false, sortOrder: 1, unit: "sqm",
        minValue: 0, maxValue: nil, maxLength: nil, options: [], dependsOn: []
    )

    static let furnishedField = SchemaField(
        id: "attr-furnished", key: "furnished", label: "Furnished", dataType: .bool, inputType: .aSwitch,
        isRequired: false, isFilterable: true, isSearchable: false, sortOrder: 2, unit: nil,
        minValue: nil, maxValue: nil, maxLength: nil, options: [], dependsOn: []
    )

    static let schema = ComposedSchema(
        schemaVersion: 1,
        category: .init(id: "cat-apartments", slug: "apartments", name: "Apartments", path: ["Real Estate", "Apartments"]),
        groups: [
            SchemaGroup(id: "g1", name: "Details", isCollapsible: false, fields: [
                bedroomsField, areaField, furnishedField,
            ]),
        ]
    )
}
