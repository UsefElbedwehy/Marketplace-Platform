import Chat
import SwiftUI

/// Buyer↔seller chat ⭐ (Phase 6). Reuses `Chat`'s `ConversationListView`/
/// `MessageThreadView` unmodified; this file is just the tab's navigation
/// wiring (App is the only place allowed to know about more than one
/// Feature module at once).
struct ChatTabView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ConversationListView { conversation in
            path.append(ChatRoute.thread(conversation))
        }
        .navigationDestination(for: ChatRoute.self) { route in
            switch route {
            case .thread(let conversation):
                MessageThreadView(conversation: conversation)
            }
        }
    }
}
