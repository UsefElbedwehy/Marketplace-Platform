import SwiftUI

public struct LoadingIndicator: View {
    @Environment(\.semanticColors) private var colors

    public init() {}

    public var body: some View {
        ProgressView()
            .tint(colors.loading)
    }
}

/// A shimmering placeholder block (skeleton loading) — `colors.skeleton` as
/// the base, animated opacity for the shimmer sweep.
public struct ShimmerView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var isAnimating = false

    private let height: CGFloat

    public init(height: CGFloat = 16) {
        self.height = height
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: theme.shape.cornerRadiusSmall)
            .fill(colors.skeleton)
            .frame(height: height)
            .opacity(isAnimating ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}
