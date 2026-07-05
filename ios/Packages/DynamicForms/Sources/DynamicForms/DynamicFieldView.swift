import DesignSystem
import DomainKit
import SwiftUI

/// One field: label (+ required marker, + unit) → the registered renderer →
/// a field-level error, if any. Hidden entirely when `state.isVisible`
/// (`visible_when`) says so.
struct DynamicFieldView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let field: SchemaField
    let state: DynamicFormState
    let registry: FieldRendererRegistry

    var body: some View {
        if state.isVisible(field) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(field.label)
                        .font(theme.typography.subheadline.font)
                        .foregroundStyle(colors.textPrimary)
                    if field.isRequired {
                        Text("*").foregroundStyle(colors.danger)
                    }
                }

                registry.renderer(for: field.inputType).body(
                    field: field,
                    options: state.visibleOptions(for: field),
                    value: Binding(
                        get: { state.value(for: field) },
                        set: { state.setValue($0, for: field) }
                    )
                )

                if let error = state.fieldErrors[field.key] {
                    Text(error).font(theme.typography.footnote.font).foregroundStyle(colors.danger)
                }
            }
        }
    }
}
