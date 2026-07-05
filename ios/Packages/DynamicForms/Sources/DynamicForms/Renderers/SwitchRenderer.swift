import DesignSystem
import DomainKit
import SwiftUI

public struct SwitchRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(SwitchRendererView(field: field, value: value))
    }
}

private struct SwitchRendererView: View {
    @Environment(\.semanticColors) private var colors
    let field: SchemaField
    @Binding var value: AttributeValue?

    var body: some View {
        Toggle(isOn: Binding(
            get: { if case .bool(let b) = value { return b } else { return false } },
            set: { value = .bool($0) }
        )) {
            EmptyView()
        }
        .labelsHidden()
        .tint(colors.primary)
        .accessibilityIdentifier("dynamic-field.\(field.key)")
    }
}
