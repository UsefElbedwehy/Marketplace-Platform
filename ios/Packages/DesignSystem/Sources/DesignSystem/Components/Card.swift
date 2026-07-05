import SwiftUI

public struct Card<Content: View>: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(16)
            .background(colors.card)
            .overlay(
                RoundedRectangle(cornerRadius: theme.shape.cornerRadiusLarge)
                    .strokeBorder(colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusLarge))
    }
}

public struct Badge: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    private let text: String
    private let tint: KeyPath<SemanticColors, Color>

    public init(_ text: String, tint: KeyPath<SemanticColors, Color> = \.badge) {
        self.text = text
        self.tint = tint
    }

    public var body: some View {
        Text(text)
            .font(theme.typography.caption.font)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colors[keyPath: tint])
            .clipShape(Capsule())
    }
}
