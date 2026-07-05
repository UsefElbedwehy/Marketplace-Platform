import DomainKit
import SwiftUI

/// A field-type registry (docs/planning/05-dynamic-schema-engine.md §6):
/// **Open/Closed** — a new field type is a new `FieldRenderer` registered in
/// `FieldRendererRegistry.standard`'s dictionary literal; `DynamicFieldView`
/// (the one dispatch point) never changes. `AnyView` is the standard SwiftUI
/// type-erasure technique for storing heterogeneous renderers in one
/// dictionary — the alternative (an associated-type `View` requirement) can't
/// be stored as `any FieldRenderer` at all.
public protocol FieldRenderer: Sendable {
    // @MainActor on the requirement only — not the whole protocol — so
    // conforming types (and their initializers) aren't themselves forced
    // MainActor-isolated; only *calling* body() is (correct, since it builds
    // SwiftUI views).
    @MainActor func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView
}

public struct FieldRendererRegistry: Sendable {
    private let renderers: [AttributeInputType: any FieldRenderer]

    public init(renderers: [AttributeInputType: any FieldRenderer]) {
        self.renderers = renderers
    }

    public static let standard = FieldRendererRegistry(renderers: [
        .textfield: TextFieldRenderer(),
        .textarea: TextAreaRenderer(),
        .stepper: NumberRenderer(),
        .slider: NumberRenderer(),
        .dropdown: DropdownRenderer(),
        .chips: ChipsRenderer(),
        .aSwitch: SwitchRenderer(),
        .datepicker: DateRenderer(),
        .media: PlaceholderRenderer(kind: "Media"),
        .map: PlaceholderRenderer(kind: "Location"),
    ])

    @MainActor
    public func renderer(for inputType: AttributeInputType) -> any FieldRenderer {
        renderers[inputType] ?? TextFieldRenderer()
    }
}
