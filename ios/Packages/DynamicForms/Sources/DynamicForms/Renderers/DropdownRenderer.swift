import DesignSystem
import DomainKit
import SwiftUI

public struct DropdownRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(DropdownRendererView(field: field, options: options, value: value))
    }
}

private struct DropdownRendererView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let field: SchemaField
    let options: [AttributeOption]
    @Binding var value: AttributeValue?

    private var selectedValue: String {
        if case .string(let s) = value { return s } else { return "" }
    }

    var body: some View {
        Menu {
            ForEach(options) { option in
                Button(option.label) { value = .string(option.value) }
            }
        } label: {
            HStack {
                Text(options.first(where: { $0.value == selectedValue })?.label ?? "Select \(field.label)…")
                    .font(theme.typography.body.font)
                    .foregroundStyle(selectedValue.isEmpty ? colors.placeholder : colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down").font(.footnote).foregroundStyle(colors.textSecondary)
            }
            .padding(12)
            .background(colors.surface)
            .overlay(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall).strokeBorder(colors.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall))
        }
        .disabled(options.isEmpty)
        .accessibilityIdentifier("dynamic-field.\(field.key)")
    }
}
