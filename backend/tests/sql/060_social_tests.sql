-- social.* (chat/favorites/reviews) + platform.outbox: participant/owner
-- isolation, cross-tenant isolation, immutable reviews + rating aggregation,
-- and notification recipient isolation — Phase 6 (Social & engagement) ⭐.

select test.act_as_service();
select test.assert_succeeds(
  'social: seed a published listing owned by the default-tenant seller to chat/favorite/review against',
  $sql$ insert into listing.listing (id, tenant_id, owner_id, category_id, title, status)
        values ('f9000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'Social Tests BMW', 'published') $sql$
);

-- === Chat ======================================================================

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_succeeds(
  'chat: buyer starts a conversation with the listing''s seller',
  $sql$ insert into social.conversation (id, tenant_id, listing_id, buyer_id, seller_id)
        values ('c9000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002') $sql$
);

select test.assert_raises(
  'chat: a conversation cannot have the same buyer and seller (check constraint)',
  $sql$ insert into social.conversation (tenant_id, listing_id, buyer_id, seller_id)
        values ('00000000-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001') $sql$
);

select test.assert_succeeds(
  'chat: buyer sends a message in their own conversation',
  $sql$ insert into social.message (id, conversation_id, sender_id, body)
        values ('e9000000-0000-0000-0000-000000000001', 'c9000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'Is this still available?') $sql$
);

select test.assert_true(
  'chat: sending a message bumps the conversation''s last_message_at',
  (select last_message_at is not null from social.conversation where id = 'c9000000-0000-0000-0000-000000000001')
);

select test.act_as('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'seller');
select test.assert_count(
  'chat: the seller (the other participant) can see the conversation and its message',
  1,
  (select count(*) from social.message where conversation_id = 'c9000000-0000-0000-0000-000000000001')
);
select test.assert_succeeds(
  'chat: the seller replies',
  $sql$ insert into social.message (conversation_id, sender_id, body) values ('c9000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'Yes, still available!') $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'catalog_editor');
select test.assert_count(
  'chat: an unrelated same-tenant user cannot see the conversation',
  0,
  (select count(*) from social.conversation where id = 'c9000000-0000-0000-0000-000000000001')
);
select test.assert_count(
  'chat: ...nor its messages',
  0,
  (select count(*) from social.message where conversation_id = 'c9000000-0000-0000-0000-000000000001')
);
select test.assert_raises(
  'chat: an unrelated user cannot insert a message into someone else''s conversation',
  $sql$ insert into social.message (conversation_id, sender_id, body) values ('c9000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000003', 'butting in') $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'buyer');
select test.assert_count(
  'chat: a different-tenant user (client_a) cannot see the conversation at all',
  0,
  (select count(*) from social.conversation where id = 'c9000000-0000-0000-0000-000000000001')
);

-- === Favorites =================================================================

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_succeeds(
  'favorites: buyer favorites the listing',
  $sql$ insert into social.favorite (tenant_id, user_id, listing_id) values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010') $sql$
);
select test.assert_raises(
  'favorites: favoriting the same listing twice violates the unique(user_id, listing_id) constraint (the service layer upserts around this; the raw constraint is the backstop)',
  $sql$ insert into social.favorite (tenant_id, user_id, listing_id) values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f9000000-0000-0000-0000-000000000010') $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'seller');
select test.assert_count(
  'favorites: the seller cannot see the buyer''s favorite (owner-only)',
  0,
  (select count(*) from social.favorite where listing_id = 'f9000000-0000-0000-0000-000000000010')
);

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_succeeds(
  'favorites: buyer unfavorites',
  $sql$ delete from social.favorite where listing_id = 'f9000000-0000-0000-0000-000000000010' $sql$
);
select test.assert_count('favorites: unfavorited — the row is gone', 0, (select count(*) from social.favorite where listing_id = 'f9000000-0000-0000-0000-000000000010'));

-- === Reviews ====================================================================

select test.assert_raises(
  'reviews: a buyer cannot review themselves (check constraint)',
  $sql$ insert into social.review (tenant_id, reviewer_id, reviewee_id, rating) values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 5) $sql$
);
select test.assert_raises(
  'reviews: rating must be between 1 and 5 (check constraint — request-level validation in reviews_service.ts is the friendlier first line of defense)',
  $sql$ insert into social.review (tenant_id, reviewer_id, reviewee_id, rating) values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 9) $sql$
);
select test.assert_succeeds(
  'reviews: buyer reviews the seller for this listing',
  $sql$ insert into social.review (id, tenant_id, reviewer_id, reviewee_id, listing_id, rating, comment)
        values ('d9000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'f9000000-0000-0000-0000-000000000010', 5, 'Great seller') $sql$
);
select test.assert_raises(
  'reviews: a duplicate (reviewer, reviewee, listing) review is rejected',
  $sql$ insert into social.review (tenant_id, reviewer_id, reviewee_id, listing_id, rating)
        values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'f9000000-0000-0000-0000-000000000010', 3) $sql$
);
select test.assert_true(
  'reviews: the SECURITY DEFINER trigger correctly bumps the reviewee''s rating_count/rating_sum even though the reviewer (not the reviewee) performed the insert',
  (select rating_count = 1 and rating_sum = 5 from identity.profile where id = 'f0000001-0000-0000-0000-000000000002'),
  (select format('rating_count=%s rating_sum=%s', rating_count, rating_sum) from identity.profile where id = 'f0000001-0000-0000-0000-000000000002')
);

select test.act_as_anon();
select test.assert_count(
  'reviews: an anonymous caller can read the seller''s reviews (public read)',
  1,
  (select count(*) from social.review where reviewee_id = 'f0000001-0000-0000-0000-000000000002')
);
select test.assert_raises(
  'reviews: anon cannot post a review',
  $sql$ insert into social.review (tenant_id, reviewer_id, reviewee_id, rating) values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 4) $sql$
);

-- === Notifications (platform.outbox) ==========================================
-- Inserted here directly (mirroring notifications_service.ts's shape) since
-- the trigger-vs-service-layer distinction (03-backend-architecture.md's
-- placement-of-logic table) means outbox rows are app-created, not DB-trigger-created.

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_succeeds(
  'notifications: a conversation participant can create a chat_message notification for the OTHER participant',
  $sql$ insert into platform.outbox (id, tenant_id, user_id, type, payload)
        values ('a9000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'chat_message', jsonb_build_object('conversationId', 'c9000000-0000-0000-0000-000000000001')) $sql$
);
select test.assert_raises(
  'notifications: a caller cannot create a notification for themselves',
  $sql$ insert into platform.outbox (tenant_id, user_id, type, payload)
        values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000001', 'chat_message', jsonb_build_object('conversationId', 'c9000000-0000-0000-0000-000000000001')) $sql$
);
select test.assert_raises(
  'notifications: a caller cannot create a notification for a conversation they are not part of',
  $sql$ insert into platform.outbox (tenant_id, user_id, type, payload)
        values ('00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000006', 'chat_message', jsonb_build_object('conversationId', 'c9000000-0000-0000-0000-000000000001')) $sql$
);
select test.assert_count(
  'notifications: the buyer (sender) does not see the notification meant for the seller in their own list',
  0,
  (select count(*) from platform.outbox where id = 'a9000000-0000-0000-0000-000000000001')
);

select test.act_as('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'seller');
select test.assert_count(
  'notifications: the seller (recipient) sees their own notification',
  1,
  (select count(*) from platform.outbox where id = 'a9000000-0000-0000-0000-000000000001')
);
select test.assert_succeeds(
  'notifications: the recipient marks it read',
  $sql$ update platform.outbox set read_at = now() where id = 'a9000000-0000-0000-0000-000000000001' $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_succeeds(
  'notifications: a non-recipient''s update attempt runs without error...',
  $sql$ update platform.outbox set read_at = null where id = 'a9000000-0000-0000-0000-000000000001' $sql$
);
select test.act_as_service();
select test.assert_true(
  '...but has no effect (RLS silently filtered the row out; still read)',
  (select read_at is not null from platform.outbox where id = 'a9000000-0000-0000-0000-000000000001')
);

delete from social.review where id = 'd9000000-0000-0000-0000-000000000001';
delete from platform.outbox where id = 'a9000000-0000-0000-0000-000000000001';
delete from social.message where conversation_id = 'c9000000-0000-0000-0000-000000000001';
delete from social.conversation where id = 'c9000000-0000-0000-0000-000000000001';
delete from listing.listing where id = 'f9000000-0000-0000-0000-000000000010';
update identity.profile set rating_count = 0, rating_sum = 0 where id = 'f0000001-0000-0000-0000-000000000002';
