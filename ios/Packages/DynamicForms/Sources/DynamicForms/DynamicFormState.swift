import Core
import DomainKit
import Observation

/// Holds the form's current values and resolves the dependency graph
/// reactively — the same logic `dashboard/src/components/DynamicFieldPreview.tsx`
/// proved out first (that component is this module's web-side sibling, per
/// docs/planning/05-dynamic-schema-engine.md §6: "mirrored on Android/Web").
/// `@Observable @MainActor` rather than the spec's literal "actor" wording —
/// this is UI-bound state with no background mutation, so it follows this
/// codebase's established pattern (`ThemeStore`, `BootViewModel`) instead.
@Observable
@MainActor
public final class DynamicFormState {
    public let schema: ComposedSchema
    public private(set) var values: [String: AttributeValue]
    public private(set) var fieldErrors: [String: String]

    public init(schema: ComposedSchema, initialValues: [String: AttributeValue] = [:]) {
        self.schema = schema
        self.values = initialValues
        self.fieldErrors = [:]
    }

    public func value(for field: SchemaField) -> AttributeValue? {
        values[field.key]
    }

    public func setValue(_ value: AttributeValue?, for field: SchemaField) {
        values[field.key] = value
        fieldErrors[field.key] = nil
    }

    /// `visible_when` — a field with no such rule is always visible.
    public func isVisible(_ field: SchemaField) -> Bool {
        guard let rule = field.dependsOn.first(where: { $0.rule == .visibleWhen }) else { return true }
        guard let equals = rule.equals else { return true }
        return values[rule.field]?.displayString == equals
    }

    /// `options_filtered_by`: the parent's *selected value* (a string) must
    /// first resolve to the parent option's *id* before it can filter this
    /// field's options by `parentOptionId` — the two are different things
    /// (mirrors the web reference implementation's `resolveVisibleOptions`).
    public func visibleOptions(for field: SchemaField) -> [AttributeOption] {
        guard let filterRule = field.dependsOn.first(where: { $0.rule == .optionsFilteredBy }) else {
            return field.options
        }
        guard let parentField = schema.allFields.first(where: { $0.key == filterRule.field }) else {
            return []
        }
        guard let parentValue = values[filterRule.field]?.displayString, !parentValue.isEmpty else {
            return []
        }
        guard let parentOption = parentField.options.first(where: { $0.value == parentValue }) else {
            return []
        }
        return field.options.filter { $0.parentOptionId == parentOption.id }
    }

    /// Client-side validation from the shipped `validation` rules, for
    /// instant feedback — the backend re-validates authoritatively regardless
    /// (`backend/src/listing_service.ts`'s `resolveAttributeValues`).
    @discardableResult
    public func validate() -> Bool {
        fieldErrors = [:]
        for field in schema.allFields where isVisible(field) {
            let value = values[field.key]
            if field.isRequired && (value == nil || value == .null || value?.displayString.isEmpty == true) {
                fieldErrors[field.key] = "\(field.label) is required."
                continue
            }
            guard let value else { continue }
            if case .number(let n) = value {
                if let min = field.minValue, n < min {
                    fieldErrors[field.key] = "\(field.label) must be at least \(Self.trimmed(min))."
                    continue
                }
                if let max = field.maxValue, n > max {
                    fieldErrors[field.key] = "\(field.label) must be at most \(Self.trimmed(max))."
                    continue
                }
            }
            if case .string(let s) = value, let maxLength = field.maxLength, s.count > maxLength {
                fieldErrors[field.key] = "\(field.label) must be at most \(maxLength) characters."
            }
        }
        return fieldErrors.isEmpty
    }

    /// Maps a 422's field errors (keyed by attribute id/key from the backend)
    /// back onto the form — closing the loop docs/planning/08-api-auth.md §3
    /// describes ("fields[] maps directly onto the dynamic form").
    public func applyServerErrors(_ errors: [FieldError]) {
        for error in errors {
            fieldErrors[error.field] = error.message
        }
    }

    /// Only visible fields' values are submitted — a hidden field (failed
    /// `visible_when`) shouldn't leak a stale value into the payload.
    public var submittableAttributes: [String: AttributeValue] {
        var result: [String: AttributeValue] = [:]
        for field in schema.allFields where isVisible(field) {
            if let value = values[field.key] {
                result[field.key] = value
            }
        }
        return result
    }

    private static func trimmed(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}
