import SwiftUI

public struct AppTextField: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme

    private let title: String
    @Binding private var text: String
    private let errorMessage: String?

    public init(_ title: String, text: Binding<String>, errorMessage: String? = nil) {
        self.title = title
        self._text = text
        self.errorMessage = errorMessage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField(title, text: $text)
                .font(theme.typography.body.font)
                .padding(12)
                .background(colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall)
                        .strokeBorder(errorMessage == nil ? colors.border : colors.danger, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall))

            if let errorMessage {
                Text(errorMessage)
                    .font(theme.typography.footnote.font)
                    .foregroundStyle(colors.danger)
            }
        }
    }
}
