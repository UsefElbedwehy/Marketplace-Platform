-- config.bundle / config.theme: guest-first public read, tenant isolation,
-- admin-only write.

select test.act_as_anon();
select test.assert_count(
  'config: anon (no tenant claim) sees both tenants'' active bundles',
  2,
  (select count(*) from config.bundle where is_active)
);

select test.act_as('f0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'buyer');
select test.assert_count(
  'config: authenticated user sees only their own tenant''s bundle',
  1,
  (select count(*) from config.bundle where is_active)
);

-- authenticated has the UPDATE grant (needed for admins — see migration
-- 20260704061100), so a non-admin's write isn't blocked at the grant level;
-- bundle_write_admin's USING clause excludes the row instead, which (like
-- the listing UPDATE case) silently affects 0 rows rather than raising.
select test.assert_succeeds(
  'config: buyer''s write attempt on config.bundle runs without error...',
  $sql$ update config.bundle set document = document || '{"hacked":true}'::jsonb where tenant_id = '00000000-0000-0000-0000-000000000002' $sql$
);
select test.act_as_service();
select test.assert_count(
  '...but has no effect (RLS filtered the row out; "hacked" key absent)',
  0,
  (select count(*) from config.bundle where tenant_id = '00000000-0000-0000-0000-000000000002' and document ? 'hacked')
);

select test.act_as('f0000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'admin');
select test.assert_succeeds(
  'config: admin CAN write to their own tenant''s config.bundle',
  $sql$ update config.bundle set version = version where tenant_id = '00000000-0000-0000-0000-000000000001' $sql$
);

select test.act_as_service();
