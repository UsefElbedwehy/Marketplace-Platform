import DesignSystem
import DomainKit
import SwiftUI

/// Local-dev sign-in — stands in for real GoTrue-backed auth (email/OTP/Apple/
/// Google, ADR-0007, unimplemented backend work) the same way the dashboard's
/// `DevIdentitySwitcher` does. Mints a token via `POST /v1/dev-auth` for one
/// of the fixed seeded identities. **Remove when real auth lands.**
struct AuthView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    @State private var viewModel = AuthViewModel()
    let onSignedIn: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Marketplace Platform")
                        .font(theme.typography.title1.font)
                        .foregroundStyle(colors.textPrimary)
                    Text("Choose a dev identity to sign in as")
                        .font(theme.typography.subheadline.font)
                        .foregroundStyle(colors.textSecondary)
                }
                .padding(.top, 40)

                Text("DEV LOGIN")
                    .font(theme.typography.caption.font)
                    .foregroundStyle(colors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colors.warning.opacity(0.15))
                    .clipShape(Capsule())

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(theme.typography.footnote.font)
                        .foregroundStyle(colors.danger)
                }

                VStack(spacing: 12) {
                    ForEach(viewModel.identities) { identity in
                        Card {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(identity.displayName)
                                        .font(theme.typography.headline.font)
                                        .foregroundStyle(colors.textPrimary)
                                    Text(identity.appRole)
                                        .font(theme.typography.footnote.font)
                                        .foregroundStyle(colors.textSecondary)
                                }
                                Spacer()
                                if viewModel.isSigningIn {
                                    LoadingIndicator()
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                if await viewModel.signIn(as: identity) {
                                    onSignedIn()
                                }
                            }
                        }
                        .disabled(viewModel.isSigningIn)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("dev-identity.\(identity.appRole)")
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(colors.background)
    }
}
