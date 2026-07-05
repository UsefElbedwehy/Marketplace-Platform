-- Fixes a real bug caught via live curl verification: notifications_service.
-- createNotification()'s `INSERT ... RETURNING` failed under RLS even though
-- outbox_insert_chat_participant's WITH CHECK was satisfied. RETURNING an
-- inserted row requires the inserting session to also have SELECT
-- visibility (per RLS) on that row — but a chat notification's `user_id` is
-- the RECIPIENT, not the sender who's performing the insert, so
-- outbox_select_own (`user_id = auth.uid()`) correctly denied the sender
-- visibility into a row addressed to someone else, and the RETURNING clause
-- itself raised the RLS violation. Confirmed by reproducing the same INSERT
-- without RETURNING (succeeded) vs. with it (failed).
--
-- Fix: an additional, precisely-scoped SELECT policy — any participant of a
-- conversation may see a chat_message notification tied to that
-- conversation, which is not a meaningful privacy loosening (both
-- participants already see each other's actual messages via social.message)
-- and happens to be exactly what's needed for the inserting sender to see
-- the row it just created for the recipient. Multiple permissive SELECT
-- policies combine with OR, so outbox_select_own's normal "list my own
-- notifications" behavior is unchanged.

drop policy if exists outbox_insert_chat_participant on platform.outbox;

create policy outbox_insert_chat_participant on platform.outbox
  for insert
  with check (
    auth.role() = 'service_role'
    or (
      type = 'chat_message'
      and user_id <> auth.uid()
      and exists (
        select 1 from social.conversation c
        where c.id = (payload ->> 'conversationId')::uuid
          and auth.uid() in (c.buyer_id, c.seller_id)
          and outbox.user_id in (c.buyer_id, c.seller_id)
      )
    )
  );

create policy outbox_select_conversation_participant on platform.outbox
  for select
  using (
    type = 'chat_message'
    and exists (
      select 1 from social.conversation c
      where c.id = (payload ->> 'conversationId')::uuid
        and auth.uid() in (c.buyer_id, c.seller_id)
    )
  );
