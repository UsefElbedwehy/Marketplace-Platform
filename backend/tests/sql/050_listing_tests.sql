-- listing.*: type-enforcement trigger, validation rules, attributes_index
-- sync (with option-value resolution), draft-vs-published visibility, and
-- the JSONB filter-query pattern GET /v1/listings will use.

select test.act_as('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'seller');

select test.assert_succeeds(
  'listing: seller can create a draft listing',
  $sql$ insert into listing.listing (id, tenant_id, owner_id, category_id, title, price, currency)
        values ('f9000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', '2019 BMW X5', 85000, 'SAR') $sql$
);

select test.assert_raises(
  'listing: type enforcement rejects text in a number attribute (mileage)',
  $sql$ insert into listing.listing_attribute_value (listing_id, attribute_id, value_text)
        values ('f9000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000004', 'a lot') $sql$
);

select test.assert_raises(
  'listing: validation rejects mileage above declared max (2,000,000)',
  $sql$ insert into listing.listing_attribute_value (listing_id, attribute_id, value_number)
        values ('f9000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000004', 5000000) $sql$
);

select test.assert_succeeds(
  'listing: correct option value (brand=bmw) is accepted',
  $sql$ insert into listing.listing_attribute_value (listing_id, attribute_id, value_option_id)
        values ('f9000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000001', 'd1000000-0000-0000-0000-000000000001') $sql$
);

select test.assert_succeeds(
  'listing: correct number value (mileage=84000) is accepted',
  $sql$ insert into listing.listing_attribute_value (listing_id, attribute_id, value_number)
        values ('f9000000-0000-0000-0000-000000000001', 'c1000000-0000-0000-0000-000000000004', 84000) $sql$
);

select test.assert_true(
  'listing: attributes_index resolves option id to its scalar value (brand=bmw) and mirrors the number (mileage=84000)',
  (select attributes_index = '{"brand":"bmw","mileage":84000}'::jsonb from listing.listing where id = 'f9000000-0000-0000-0000-000000000001'),
  (select attributes_index::text from listing.listing where id = 'f9000000-0000-0000-0000-000000000001')
);

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_count(
  'listing: a draft listing is invisible to a different (non-owner, non-moderator) user',
  0,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000001')
);

select test.act_as('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'seller');
select test.assert_succeeds(
  'listing: owner publishes their own listing',
  $sql$ update listing.listing set status = 'published' where id = 'f9000000-0000-0000-0000-000000000001' $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_count(
  'listing: a published listing is now visible to any buyer',
  1,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000001')
);
select test.assert_count(
  'listing: filtering by attributes_index (brand=bmw AND mileage<100000) finds it',
  1,
  (select count(*) from listing.listing
     where attributes_index @> '{"brand":"bmw"}'::jsonb
       and (attributes_index ->> 'mileage')::numeric < 100000)
);
-- An UPDATE blocked by RLS's USING clause doesn't raise — the row is simply
-- not visible to update, so it silently affects 0 rows. Unlike INSERT's WITH
-- CHECK (which does raise), this must be asserted by checking the row
-- afterward, not by expecting an exception.
select test.assert_succeeds(
  'listing: a non-owner buyer''s edit attempt runs without error...',
  $sql$ update listing.listing set title = 'stolen listing' where id = 'f9000000-0000-0000-0000-000000000001' $sql$
);

select test.act_as_service();
select test.assert_count(
  '...but has no effect (RLS silently filtered the row out of the UPDATE)',
  0,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000001' and title = 'stolen listing')
);

delete from listing.listing where id = 'f9000000-0000-0000-0000-000000000001';

-- === Moderation RLS (the row-access gate the app-layer state machine in
-- backend/src/listing_service.ts sits on top of — see its unit tests for the
-- transition-legality/moderator-only-targets logic; this only exercises what
-- Postgres itself allows/denies) ===============================================

select test.act_as('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'seller');
select test.assert_succeeds(
  'moderation: seller creates a listing and submits it for review',
  $sql$ insert into listing.listing (id, tenant_id, owner_id, category_id, title, status)
        values ('f9000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'f0000001-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000001', 'Pending Review Test', 'pending_review') $sql$
);

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');
select test.assert_count(
  'moderation: a pending_review listing is invisible to an unrelated buyer',
  0,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000002')
);
select test.assert_succeeds(
  'moderation: a buyer''s attempt to approve someone else''s listing runs without error...',
  $sql$ update listing.listing set status = 'published' where id = 'f9000000-0000-0000-0000-000000000002' $sql$
);

select test.act_as_service();
select test.assert_count(
  '...but has no effect (RLS filtered the row out; still pending_review)',
  1,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000002' and status = 'pending_review')
);

select test.act_as('f0000001-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'moderator');
select test.assert_count(
  'moderation: a moderator CAN see a pending_review listing owned by someone else',
  1,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000002')
);
select test.assert_succeeds(
  'moderation: a moderator CAN approve a listing they don''t own',
  $sql$ update listing.listing set status = 'published' where id = 'f9000000-0000-0000-0000-000000000002' $sql$
);
select test.assert_count(
  'moderation: the approval actually persisted',
  1,
  (select count(*) from listing.listing where id = 'f9000000-0000-0000-0000-000000000002' and status = 'published')
);

select test.act_as_service();
delete from listing.listing where id = 'f9000000-0000-0000-0000-000000000002';
