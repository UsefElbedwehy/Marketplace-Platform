import SwiftUI

public struct PrimaryButton: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme

    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(theme.typography.headline.font)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .background(colors.primary)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusMedium))
        .disabled(isLoading)
    }
}

public struct SecondaryButton: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme

    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.headline.font)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(colors.surface)
        .foregroundStyle(colors.primary)
        .overlay(
            RoundedRectangle(cornerRadius: theme.shape.cornerRadiusMedium)
                .strokeBorder(colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.shape.cornerRadiusMedium))
    }
}
