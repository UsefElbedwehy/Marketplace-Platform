import DesignSystem
import DomainKit
import SwiftUI

/// A min/max pair for a filterable *number* field — outside `DynamicForms`'
/// single-value model (that's for create-listing values, not filter ranges),
/// so Search owns this small piece itself.
struct RangeFilterRow: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let field: SchemaField
    @Binding var range: AttributeRangeFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(field.label).font(theme.typography.subheadline.font).foregroundStyle(colors.textPrimary)
                if let unit = field.unit {
                    Text("(\(unit))").font(theme.typography.caption.font).foregroundStyle(colors.textSecondary)
                }
            }
            HStack(spacing: 12) {
                numberField("Min", value: Binding(get: { range.gte }, set: { range.gte = $0 }))
                numberField("Max", value: Binding(get: { range.lte }, set: { range.lte = $0 }))
            }
        }
    }

    private func numberField(_ placeholder: String, value: Binding<Double?>) -> some View {
        TextField(placeholder, text: Binding(
            get: { value.wrappedValue.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(Int($0)) : String($0) } ?? "" },
            set: { value.wrappedValue = $0.isEmpty ? nil : Double($0) }
        ))
        #if os(iOS)
        .keyboardType(.decimalPad)
        #endif
        .padding(10)
        .background(colors.surface)
        .overlay(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall).strokeBorder(colors.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall))
    }
}
