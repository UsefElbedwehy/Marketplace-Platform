import DesignSystem
import DomainKit
import SwiftUI

/// `media`/`map` — not implemented, matching the web reference
/// implementation's own `DynamicFieldPreview.tsx` (`"{inputType} picker (not
/// implemented in this preview)"`). Real media upload needs Supabase Storage
/// wiring that doesn't exist yet anywhere in this codebase (no
/// `contract/openapi` endpoint, no dashboard support either) — faking it here
/// would be UI theater, not a working feature.
public struct PlaceholderRenderer: FieldRenderer {
    let kind: String

    public init(kind: String) {
        self.kind = kind
    }

    public func body(field: SchemaField, options: [AttributeOption], value: Binding<AttributeValue?>) -> AnyView {
        AnyView(PlaceholderRendererView(kind: kind))
    }
}

private struct PlaceholderRendererView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let kind: String

    var body: some View {
        Text("\(kind) picker (not implemented)")
            .font(theme.typography.footnote.font)
            .foregroundStyle(colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall)
                    .strokeBorder(colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
    }
}
