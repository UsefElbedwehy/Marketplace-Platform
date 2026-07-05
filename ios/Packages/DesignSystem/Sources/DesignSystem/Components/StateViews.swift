import SwiftUI

public struct EmptyStateView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    private let title: String
    private let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(title).font(theme.typography.headline.font).foregroundStyle(colors.textPrimary)
            Text(message).font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

public struct ErrorStateView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    private let message: String
    private let retry: (() -> Void)?

    public init(message: String, retry: (() -> Void)? = nil) {
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(theme.typography.subheadline.font)
                .foregroundStyle(colors.danger)
                .multilineTextAlignment(.center)
            if let retry {
                SecondaryButton("Try again", action: retry)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

public struct OfflineBanner: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        Text("You're offline")
            .font(theme.typography.footnote.font)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(colors.offline)
    }
}
