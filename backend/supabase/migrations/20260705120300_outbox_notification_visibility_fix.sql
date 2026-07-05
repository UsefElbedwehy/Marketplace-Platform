-- Reverts 20260705120200's outbox_select_conversation_participant policy.
-- It correctly let a notification's sender see/RETURN the row they just
-- created (fixing the RLS-on-RETURNING bug from that migration), but as a
-- side effect it also let BOTH conversation participants see EACH OTHER's
-- chat_message notifications in their regular "list my notifications" view
-- — caught live: a buyer who sent a message saw a spurious notification
-- meant for the seller in their own GET /v1/notifications response.
--
-- Fixed at the root instead (backend/src/notifications_service.ts):
-- createNotification() no longer uses INSERT ... RETURNING at all — it
-- generates id/created_at itself and constructs the response from its own
-- input, so nothing ever needs to SELECT a row addressed to someone else.
-- This policy is no longer needed for anything.

drop policy if exists outbox_select_conversation_participant on platform.outbox;
