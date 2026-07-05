import DomainKit

/// The public surface a host `NavigationStack` (the App's `TabCoordinator`)
/// pushes — per ADR-0015, "each feature package exposes... its route enum."
/// Carries the full `Conversation` since `ConversationListView` already has
/// it in hand when the user taps a row, avoiding a redundant fetch.
public enum ChatRoute: Hashable, Sendable {
    case thread(Conversation)
}
