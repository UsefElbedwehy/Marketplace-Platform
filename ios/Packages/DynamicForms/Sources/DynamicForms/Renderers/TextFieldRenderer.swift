import DesignSystem
import DomainKit
import SwiftUI

public struct TextFieldRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(TextFieldRendererView(field: field, value: value))
    }
}

private struct TextFieldRendererView: View {
    let field: SchemaField
    @Binding var value: AttributeValue?

    var body: some View {
        AppTextField(
            field.label,
            text: Binding(
                get: { if case .string(let s) = value { return s } else { return "" } },
                set: { value = $0.isEmpty ? nil : .string($0) }
            )
        )
        .accessibilityIdentifier("dynamic-field.\(field.key)")
    }
}

public struct TextAreaRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(TextAreaRendererView(value: value))
    }
}

private struct TextAreaRendererView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @Binding var value: AttributeValue?

    private var text: Binding<String> {
        Binding(
            get: { if case .string(let s) = value { return s } else { return "" } },
            set: { value = $0.isEmpty ? nil : .string($0) }
        )
    }

    var body: some View {
        TextEditor(text: text)
            .frame(minHeight: 80)
            .padding(4)
            .background(colors.surface)
            .overlay(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall).strokeBorder(colors.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall))
    }
}
