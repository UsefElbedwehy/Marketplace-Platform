-- social schema: chat, favorites, reviews ⭐ (Phase 6 — Social & engagement)
-- plus platform.outbox (notification fan-out) and an identity.profile
-- extension for public seller-profile fields.
--
-- Realtime note: docs/planning/03-backend-architecture.md §6 specifies chat
-- messages/notifications as delivered via Supabase Realtime channels (a
-- contract-documented channel/topic per conversation and per user). Realtime
-- itself requires Supabase's hosted/Docker Realtime service, unavailable in
-- this environment (see backend/README.md's local-development caveat — the
-- same reason real GoTrue auth is stubbed with v1-dev-auth). v1-chat and
-- v1-notifications therefore expose plain REST poll endpoints instead. The
-- tables/RLS/service layer below are identical either way; only the
-- transport (poll vs. subscribe) differs, so swapping in real Realtime later
-- is additive, not a redesign.

create schema if not exists social;

-- === Chat =====================================================================

create table social.conversation (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references platform.tenant(id),
  listing_id uuid not null references listing.listing(id) on delete cascade,
  buyer_id uuid not null references auth.users(id),
  seller_id uuid not null references auth.users(id),
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (listing_id, buyer_id),
  check (buyer_id <> seller_id)
);

comment on table social.conversation is
  'One thread per (listing, buyer) — re-opening chat about the same listing resumes the same conversation. seller_id is captured from listing.owner_id at creation time (chat_service.ts) rather than joined live, so RLS never needs a join to listing.';

create index conversation_buyer_idx on social.conversation (buyer_id, last_message_at desc);
create index conversation_seller_idx on social.conversation (seller_id, last_message_at desc);
create index conversation_listing_idx on social.conversation (listing_id);

create table social.message (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references social.conversation(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text not null check (length(body) between 1 and 4000),
  read_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table social.message is
  'A single chat message. read_at is set by the recipient fetching/opening their conversation (v1-chat), not by the sender.';

create index message_conversation_idx on social.message (conversation_id, created_at);

-- Keeps conversation.last_message_at current without every reader needing a
-- max(created_at) subquery — a derived value maintained by trigger, not
-- client math, per docs/planning/04-database-architecture.md §7. Runs as the
-- inserting participant (no SECURITY DEFINER), so still subject to
-- conversation's own UPDATE policy below.
create or replace function social.bump_conversation_last_message() returns trigger
language plpgsql as $$
begin
  update social.conversation set last_message_at = new.created_at, updated_at = now() where id = new.conversation_id;
  return new;
end;
$$;

create trigger message_bump_conversation
  after insert on social.message
  for each row execute function social.bump_conversation_last_message();

-- === Favorites ================================================================

create table social.favorite (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references platform.tenant(id),
  user_id uuid not null references auth.users(id),
  listing_id uuid not null references listing.listing(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

comment on table social.favorite is 'A buyer''s saved listing — owner-only, per docs/planning/04-database-architecture.md §4.';

create index favorite_user_idx on social.favorite (user_id, created_at desc);
create index favorite_listing_idx on social.favorite (listing_id);

-- === Reviews ==================================================================

create table social.review (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references platform.tenant(id),
  reviewer_id uuid not null references auth.users(id),
  reviewee_id uuid not null references auth.users(id),
  listing_id uuid references listing.listing(id) on delete set null,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (reviewer_id, reviewee_id, listing_id),
  check (reviewer_id <> reviewee_id)
);

comment on table social.review is
  'A buyer''s rating of a seller, optionally tied to the listing that prompted it. Immutable once posted (no update/delete policy) — keeps RLS simple and matches the common "reviews are permanent feedback" convention. Aggregated onto identity.profile.rating_count/rating_sum by a trigger, not client math.';

create index review_reviewee_idx on social.review (reviewee_id, created_at desc);

-- === identity.profile extension (seller profile fields) ======================

alter table identity.profile
  add column avatar_url text,
  add column bio text,
  add column rating_count int not null default 0,
  add column rating_sum int not null default 0;

comment on column identity.profile.rating_count is 'Maintained by social.review_bump_rating trigger — never written directly by application code.';
comment on column identity.profile.rating_sum is 'Maintained by social.review_bump_rating trigger. Average = rating_sum::numeric / nullif(rating_count, 0), computed at read time to avoid float-drift from a stored average.';

create or replace function social.bump_reviewee_rating() returns trigger
language plpgsql as $$
begin
  update identity.profile set rating_count = rating_count + 1, rating_sum = rating_sum + new.rating
    where id = new.reviewee_id;
  return new;
end;
$$;

create trigger review_bump_rating
  after insert on social.review
  for each row execute function social.bump_reviewee_rating();

-- === platform.outbox (notification fan-out) ===================================
--
-- docs/planning/03-backend-architecture.md §6: "an outbox table + Realtime
-- channel per user; push (APNs) fan-out via a provider port." The row itself
-- is the source of truth an in-app notification list reads (GET
-- /v1/notifications); push delivery is attempted by the service layer
-- through a PushPort (backend/src/ports/push_port.ts) as part of the same
-- insert. Real APNs credentials aren't available in this environment, so the
-- port's only implementation here is a logging no-op adapter — mirrors the
-- payments-provider-port pattern already documented (docs/planning/03 §7).
-- delivered_at is stamped at insert time (whether or not the adapter could
-- "send" it); only read_at is ever updated later, by the recipient.

create table platform.outbox (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references platform.tenant(id),
  user_id uuid not null references auth.users(id),
  type text not null check (type in ('chat_message', 'listing_favorited', 'review_received')),
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table platform.outbox is
  'Per-user notification record. Written by application-layer services (never a client, never a DB trigger — creating a notification is orchestration/side-effect logic, not a data invariant, per docs/planning/03-backend-architecture.md''s placement-of-logic table) after the triggering event (e.g. a chat message) is committed in the same request.';

create index outbox_user_created_idx on platform.outbox (user_id, created_at desc);

-- === Grants ===================================================================

grant usage on schema social to anon, authenticated, service_role;
grant select, insert, update on social.conversation, social.message to authenticated;
grant select, insert, delete on social.favorite to authenticated;
grant select, insert on social.review to authenticated;
grant select, insert, update, delete on social.conversation, social.message, social.favorite, social.review to service_role;
grant select, insert, update on platform.outbox to authenticated, service_role;

-- === RLS ======================================================================

alter table social.conversation enable row level security;
alter table social.message enable row level security;
alter table social.favorite enable row level security;
alter table social.review enable row level security;
alter table platform.outbox enable row level security;

create policy conversation_select_participant on social.conversation
  for select
  using (
    (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id())
    and (buyer_id = auth.uid() or seller_id = auth.uid() or auth.role() = 'service_role')
  );

create policy conversation_insert_buyer on social.conversation
  for insert
  with check (buyer_id = auth.uid() and tenant_id = platform.current_tenant_id());

-- Only last_message_at/updated_at ever change today, and only via the
-- message-insert trigger above (which runs as the sending participant, so
-- still needs its own UPDATE grant through this policy) — no direct
-- participant-driven update path exists yet.
create policy conversation_update_participant on social.conversation
  for update
  using (buyer_id = auth.uid() or seller_id = auth.uid() or auth.role() = 'service_role')
  with check (buyer_id = auth.uid() or seller_id = auth.uid() or auth.role() = 'service_role');

create policy message_select_participant on social.message
  for select
  using (exists (
    select 1 from social.conversation c
    where c.id = message.conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
  ) or auth.role() = 'service_role');

create policy message_insert_participant on social.message
  for insert
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from social.conversation c
      where c.id = message.conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

-- A recipient marks a message read_at when they open the conversation;
-- simplest correct rule is "either participant may update read_at on a
-- message in their own conversation" rather than distinguishing sender from
-- recipient at the RLS layer.
create policy message_update_participant on social.message
  for update
  using (exists (
    select 1 from social.conversation c
    where c.id = message.conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
  ))
  with check (exists (
    select 1 from social.conversation c
    where c.id = message.conversation_id and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
  ));

create policy favorite_all_own on social.favorite
  for all
  using (
    (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id())
    and (user_id = auth.uid() or auth.role() = 'service_role')
  )
  with check (user_id = auth.uid() or auth.role() = 'service_role');

-- Reviews are public read (they're what a seller profile displays) — anyone
-- in the tenant including anon, mirroring the "published listings are
-- public" precedent in listing.listing_select.
create policy review_select_public on social.review
  for select
  using (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id());

create policy review_insert_reviewer on social.review
  for insert
  with check (reviewer_id = auth.uid() and tenant_id = platform.current_tenant_id());

create policy outbox_select_own on platform.outbox
  for select
  using (
    (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id())
    and (user_id = auth.uid() or auth.role() = 'service_role')
  );

-- Scoped precisely rather than "any authenticated user may insert a
-- notification for anyone" — an authenticated caller may only create a
-- chat_message notification for the OTHER participant of a conversation
-- they are themselves part of. Additional notification types (favorited,
-- review_received) would need their own matching clause here when wired up;
-- service_role (used for tests/ops) bypasses this entirely.
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

-- Only read_at is ever updated by a client, and only the recipient's own row.
create policy outbox_update_own on platform.outbox
  for update
  using (user_id = auth.uid() or auth.role() = 'service_role')
  with check (user_id = auth.uid() or auth.role() = 'service_role');
