import DesignSystem
import DomainKit
import SwiftUI

/// Handles both `stepper` and `slider` input types — the seed data only uses
/// `stepper` (docs/planning/05's field-type registry lists both under one
/// "NumberRenderer"); a numeric `TextField` with a decimal keypad covers both
/// without over-building a literal `+`/`-` stepper control or a `Slider`
/// nobody's schema asks for yet.
public struct NumberRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(NumberRendererView(field: field, value: value))
    }
}

private struct NumberRendererView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let field: SchemaField
    @Binding var value: AttributeValue?
    @State private var text: String = ""

    var body: some View {
        HStack {
            TextField(field.label, text: $text)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .font(theme.typography.body.font)
                .onChange(of: text) { _, newValue in
                    value = newValue.isEmpty ? nil : Double(newValue).map { .number($0) }
                }
                .accessibilityIdentifier("dynamic-field.\(field.key)")
            if let unit = field.unit {
                Text(unit).font(theme.typography.footnote.font).foregroundStyle(colors.textSecondary)
            }
        }
        .padding(12)
        .background(colors.surface)
        .overlay(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall).strokeBorder(colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall))
        .onAppear {
            if case .number(let n) = value { text = n.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(n)) : String(n) }
        }
    }
}
