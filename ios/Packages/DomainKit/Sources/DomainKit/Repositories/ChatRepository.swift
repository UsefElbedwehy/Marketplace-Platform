/// docs/planning/03-backend-architecture.md §6 specifies chat as delivered
/// via Supabase Realtime channels; real Realtime needs the hosted/Docker
/// Realtime service, unavailable in this environment (the same gap as real
/// GoTrue-backed auth) — so `fetchMessages`/`fetchConversations` are plain
/// poll-based REST reads, not subscriptions. The channel/topic contract this
/// would use is still documented (see backend/supabase/migrations/
/// 20260705120000_social_and_notifications_schema.sql's header) so swapping
/// in real Realtime later is additive, not a redesign.
public protocol ChatRepository: Sendable {
    func fetchConversations() async throws -> [Conversation]
    func startConversation(listingId: String) async throws -> Conversation
    func fetchMessages(conversationId: String) async throws -> [Message]
    func sendMessage(conversationId: String, body: String) async throws -> Message
}
