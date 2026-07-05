import DesignSystem
import DomainKit
import SwiftUI

public struct ChipsRenderer: FieldRenderer {
    public init() {}

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(ChipsRendererView(field: field, options: options, value: value))
    }
}

private struct ChipsRendererView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let field: SchemaField
    let options: [AttributeOption]
    @Binding var value: AttributeValue?

    private var selected: [String] {
        if case .stringArray(let a) = value { return a } else { return [] }
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                let isSelected = selected.contains(option.value)
                Button {
                    var next = selected
                    if isSelected { next.removeAll { $0 == option.value } } else { next.append(option.value) }
                    value = next.isEmpty ? nil : .stringArray(next)
                } label: {
                    Text(option.label)
                        .font(theme.typography.footnote.font)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? colors.primary : colors.surface)
                        .foregroundStyle(isSelected ? .white : colors.textPrimary)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(colors.border, lineWidth: isSelected ? 0 : 1))
                }
            }
        }
    }
}

/// A minimal wrapping horizontal layout for chip buttons — `HStack` doesn't
/// wrap, and this is the only place in `DynamicForms` that needs it.
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + (rowWidth > 0 ? spacing : 0)
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : rowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
