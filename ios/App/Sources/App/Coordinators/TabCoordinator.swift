import Observation
import SwiftUI

/// Owns the signed-in shell's tab selection and one `NavigationPath` per tab
/// (docs/planning/02-ios-architecture.md §2's `TabCoordinator`). Each tab's
/// real content is a Feature module in Phase 4 (`Features/Listings`,
/// `Features/Search`, …) — for now these are placeholders proving the shell,
/// routing, and theming, not the features themselves.
@Observable
@MainActor
final class TabCoordinator {
    enum Tab: String, CaseIterable, Identifiable {
        case home, search, sell, chat, profile
        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: return "Home"
            case .search: return "Search"
            case .sell: return "Sell"
            case .chat: return "Chat"
            case .profile: return "Profile"
            }
        }

        var systemImage: String {
            switch self {
            case .home: return "house"
            case .search: return "magnifyingglass"
            case .sell: return "plus.circle"
            case .chat: return "bubble.left.and.bubble.right"
            case .profile: return "person.crop.circle"
            }
        }
    }

    var selectedTab: Tab = .home
    var homePath = NavigationPath()
    var searchPath = NavigationPath()
    var sellPath = NavigationPath()
    var chatPath = NavigationPath()
    var profilePath = NavigationPath()
}
