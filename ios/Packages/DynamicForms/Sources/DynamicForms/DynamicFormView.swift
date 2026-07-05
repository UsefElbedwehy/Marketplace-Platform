import DesignSystem
import DomainKit
import SwiftUI

/// Renders every group/field in a `ComposedSchema` — the same generic
/// renderer produces the Cars form, the Apartments form, and the Phones
/// form from metadata alone (docs/planning/11-roadmap.md Phase 4 exit
/// criterion: "zero vertical-specific screen code").
public struct DynamicFormView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @Bindable private var state: DynamicFormState
    private let registry: FieldRendererRegistry

    public init(state: DynamicFormState, registry: FieldRendererRegistry = .standard) {
        self.state = state
        self.registry = registry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if state.schema.groups.isEmpty {
                Text("This category has no custom attributes.")
                    .font(theme.typography.subheadline.font)
                    .foregroundStyle(colors.textSecondary)
            }
            ForEach(state.schema.groups) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.name.uppercased())
                        .font(theme.typography.caption.font)
                        .foregroundStyle(colors.textSecondary)
                    ForEach(group.fields.sorted(by: { $0.sortOrder < $1.sortOrder })) { field in
                        DynamicFieldView(field: field, state: state, registry: registry)
                    }
                }
            }
        }
    }
}
