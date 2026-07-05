/// The Dynamic Category & Attribute Engine's domain shapes ⭐ — mirrors
/// `contract/openapi/v1/openapi.yaml`'s `CategoryTreeNode`/`ComposedSchema`/
/// `SchemaGroup`/`SchemaField`/`AttributeOption`/`AttributeDependency`.
/// `DataKit`'s `CategoryRepositoryImpl` maps its DTOs onto these.
public struct CategoryTreeNode: Hashable, Sendable, Identifiable {
    public let id: String
    public let slug: String
    public let name: String
    public let icon: String?
    public let sortOrder: Int
    public let isLeaf: Bool
    public let children: [CategoryTreeNode]

    public init(id: String, slug: String, name: String, icon: String?, sortOrder: Int, isLeaf: Bool, children: [CategoryTreeNode]) {
        self.id = id
        self.slug = slug
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isLeaf = isLeaf
        self.children = children
    }
}

public struct AttributeOption: Equatable, Sendable, Identifiable {
    public let id: String
    public let value: String
    public let label: String
    public let parentOptionId: String?

    public init(id: String, value: String, label: String, parentOptionId: String?) {
        self.id = id
        self.value = value
        self.label = label
        self.parentOptionId = parentOptionId
    }
}

public enum DependencyRule: String, Equatable, Sendable {
    case visibleWhen = "visible_when"
    case requiredWhen = "required_when"
    case optionsFilteredBy = "options_filtered_by"
}

/// `equals` is the only condition shape this platform's seed data or backend
/// ever produces (see `catalog.attribute_dependency.condition`) — flattened
/// to a string for comparison against option `value`s / stringified bools.
public struct AttributeDependency: Equatable, Sendable {
    public let field: String
    public let rule: DependencyRule
    public let equals: String?

    public init(field: String, rule: DependencyRule, equals: String?) {
        self.field = field
        self.rule = rule
        self.equals = equals
    }
}

public enum AttributeDataType: String, Equatable, Sendable {
    case text, number, bool, date, option
    case optionMulti = "option_multi"
    case media, location
}

public enum AttributeInputType: String, Equatable, Sendable {
    case textfield, textarea, stepper, slider, dropdown, chips
    case aSwitch = "switch"
    case datepicker, media, map
}

public struct SchemaField: Equatable, Sendable, Identifiable {
    /// The underlying attribute id — read-only app clients don't need it for
    /// anything but `Identifiable`/keying; admin clients (the dashboard) use
    /// it to target write endpoints.
    public let id: String
    public let key: String
    public let label: String
    public let dataType: AttributeDataType
    public let inputType: AttributeInputType
    public let isRequired: Bool
    public let isFilterable: Bool
    public let isSearchable: Bool
    public let sortOrder: Int
    public let unit: String?
    public let minValue: Double?
    public let maxValue: Double?
    public let maxLength: Int?
    public let options: [AttributeOption]
    public let dependsOn: [AttributeDependency]

    public init(
        id: String, key: String, label: String, dataType: AttributeDataType, inputType: AttributeInputType,
        isRequired: Bool, isFilterable: Bool, isSearchable: Bool, sortOrder: Int, unit: String?,
        minValue: Double?, maxValue: Double?, maxLength: Int?, options: [AttributeOption], dependsOn: [AttributeDependency]
    ) {
        self.id = id
        self.key = key
        self.label = label
        self.dataType = dataType
        self.inputType = inputType
        self.isRequired = isRequired
        self.isFilterable = isFilterable
        self.isSearchable = isSearchable
        self.sortOrder = sortOrder
        self.unit = unit
        self.minValue = minValue
        self.maxValue = maxValue
        self.maxLength = maxLength
        self.options = options
        self.dependsOn = dependsOn
    }
}

public struct SchemaGroup: Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let isCollapsible: Bool
    public let fields: [SchemaField]

    public init(id: String, name: String, isCollapsible: Bool, fields: [SchemaField]) {
        self.id = id
        self.name = name
        self.isCollapsible = isCollapsible
        self.fields = fields
    }
}

public struct ComposedSchema: Equatable, Sendable {
    public struct CategoryRef: Equatable, Sendable {
        public let id: String
        public let slug: String
        public let name: String
        public let path: [String]

        public init(id: String, slug: String, name: String, path: [String]) {
            self.id = id
            self.slug = slug
            self.name = name
            self.path = path
        }
    }

    /// Bumped on any change to this category's groups/attributes/options/
    /// dependencies — the signal that a schema-edit happened server-side.
    public let schemaVersion: Int
    public let category: CategoryRef
    public let groups: [SchemaGroup]

    public init(schemaVersion: Int, category: CategoryRef, groups: [SchemaGroup]) {
        self.schemaVersion = schemaVersion
        self.category = category
        self.groups = groups
    }

    /// All fields across all groups, flattened — the shape `DynamicForms`'
    /// dependency resolution wants (a field can depend on one in another
    /// group).
    public var allFields: [SchemaField] {
        groups.flatMap(\.fields)
    }
}
