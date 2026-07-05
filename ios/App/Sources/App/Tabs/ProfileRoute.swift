/// Profile-tab-only navigation targets — favorites/notifications are
/// reachable from here rather than their own top-level tab (Home/Search/
/// Sell/Chat/Profile already fill the tab bar); this is App-owned rather
/// than living in a Feature route enum since it spans Listings (Saved) and
/// a plain App-hosted view (Notifications).
enum ProfileRoute: Hashable {
    case savedListings
    case notifications
}
