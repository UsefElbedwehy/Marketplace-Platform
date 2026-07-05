import DesignSystem
import DomainKit
import SwiftUI

/// A near-duplicate of `Listings.ListingRowView` — Search may not depend on
/// the Listings package (Feature isolation, 01-system-architecture.md §4),
/// so this small presentational view is intentionally re-declared here
/// rather than shared.
struct SearchResultRowView: View {
    @Environment(\.semanticColors) private var colors
    @Environment(\.theme) private var theme
    let listing: Listing

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title).font(theme.typography.headline.font).foregroundStyle(colors.textPrimary)
                    Text(priceText).font(theme.typography.subheadline.font).foregroundStyle(colors.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var priceText: String {
        guard let price = listing.price else { return "No price" }
        let currency = listing.currency ?? ""
        let formatted = price.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(price)) : String(price)
        return "\(formatted) \(currency)"
    }
}
