-- identity.profile: self-edit works; app_role/tenant_id privilege escalation
-- is blocked by the trigger (RLS alone can't stop it — see migration
-- 20260704061000's comment).

select test.act_as('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'buyer');

select test.assert_succeeds(
  'identity: user can update own display_name',
  $sql$ update identity.profile set display_name = 'Renamed Buyer' where id = 'f0000001-0000-0000-0000-000000000001' $sql$
);

select test.assert_raises(
  'identity: user cannot self-promote app_role',
  $sql$ update identity.profile set app_role = 'admin' where id = 'f0000001-0000-0000-0000-000000000001' $sql$
);

select test.assert_count(
  'identity: app_role unchanged after blocked escalation attempt',
  0,
  (select count(*) from identity.profile where id = 'f0000001-0000-0000-0000-000000000001' and app_role = 'admin')
);

select test.assert_count(
  'identity: user cannot read another tenant''s profile (non-admin, RLS silently filters)',
  0,
  (select count(*) from identity.profile where id = 'f0000001-0000-0000-0000-000000000005')
);

-- === Admin role management (migration 20260704155058) ======================
-- Closes the gap the original trigger left: an admin must be able to change
-- ANOTHER user's role, but never their own, even as an admin.

select test.act_as('f0000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'admin');

select test.assert_succeeds(
  'admin role mgmt: admin CAN change another user''s app_role',
  $sql$ update identity.profile set app_role = 'seller' where id = 'f0000001-0000-0000-0000-000000000001' $sql$
);
select test.assert_count(
  'admin role mgmt: the promotion actually persisted',
  1,
  (select count(*) from identity.profile where id = 'f0000001-0000-0000-0000-000000000001' and app_role = 'seller')
);

select test.assert_raises(
  'admin role mgmt: an admin cannot change their OWN app_role, even as admin',
  $sql$ update identity.profile set app_role = 'super_admin' where id = 'f0000001-0000-0000-0000-000000000004' $sql$
);
select test.assert_count(
  'admin role mgmt: admin''s own role unchanged after the blocked self-escalation attempt',
  0,
  (select count(*) from identity.profile where id = 'f0000001-0000-0000-0000-000000000004' and app_role = 'super_admin')
);

select test.assert_raises(
  'admin role mgmt: tenant_id remains unchangeable even by an admin',
  $sql$ update identity.profile set tenant_id = '00000000-0000-0000-0000-000000000002' where id = 'f0000001-0000-0000-0000-000000000001' $sql$
);

-- A non-admin (catalog_editor) attempting to change someone else's role is
-- blocked by profile_update_admin's RLS USING clause — an UPDATE, so this
-- silently affects 0 rows rather than raising (see backend/tests/README.md).
select test.act_as('f0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'catalog_editor');
select test.assert_succeeds(
  'admin role mgmt: a non-admin''s attempt to change another user''s role runs without error...',
  $sql$ update identity.profile set app_role = 'admin' where id = 'f0000001-0000-0000-0000-000000000006' $sql$
);

select test.act_as_service();
select test.assert_count(
  '...but has no effect (RLS filtered the row out; still moderator)',
  1,
  (select count(*) from identity.profile where id = 'f0000001-0000-0000-0000-000000000006' and app_role = 'moderator')
);

-- Restore the fixture buyer's role so later test files (which set app_role
-- explicitly via test.act_as, not by reading this table) still describe
-- their fixtures accurately if ever queried directly.
update identity.profile set app_role = 'buyer' where id = 'f0000001-0000-0000-0000-000000000001';
