import DesignSystem
import DomainKit
import SwiftUI

/// Reused by the feed, "my listings", and the moderation queue — the same
/// row for any category, since a `Listing` carries no vertical-specific
/// shape (docs/planning/05 §7: filters/rows key off `attributesIndex`, not
/// per-category columns).
public struct ListingRowView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let listing: Listing

    public init(listing: Listing) {
        self.listing = listing
    }

    public var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(theme.typography.headline.font)
                        .foregroundStyle(colors.textPrimary)
                    Text(priceText)
                        .font(theme.typography.subheadline.font)
                        .foregroundStyle(colors.textSecondary)
                }
                Spacer()
                Badge(listing.status.rawValue, tint: badgeTint)
            }
        }
    }

    private var priceText: String {
        guard let price = listing.price else { return "No price" }
        let currency = listing.currency ?? ""
        return "\(Self.formatted(price)) \(currency)"
    }

    private var badgeTint: KeyPath<SemanticColors, Color> {
        switch listing.status {
        case .published: return \.success
        case .rejected: return \.danger
        case .sold: return \.info
        default: return \.secondary
        }
    }

    private static func formatted(_ price: Double) -> String {
        price.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(price)) : String(price)
    }
}
