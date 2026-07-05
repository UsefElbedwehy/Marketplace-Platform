-- Test fixtures: users/profiles across both seeded tenants (default,
-- client_a) covering every role the RLS suite needs to exercise.
-- platform.tenant rows already exist from seed/00_reference_config.sql.

set role service_role;

insert into auth.users (id, email) values
  ('f0000001-0000-0000-0000-000000000001', 'buyer.default@test.local'),
  ('f0000001-0000-0000-0000-000000000002', 'seller.default@test.local'),
  ('f0000001-0000-0000-0000-000000000003', 'catalogeditor.default@test.local'),
  ('f0000001-0000-0000-0000-000000000004', 'admin.default@test.local'),
  ('f0000001-0000-0000-0000-000000000005', 'buyer.clienta@test.local'),
  ('f0000001-0000-0000-0000-000000000006', 'moderator.default@test.local');

insert into identity.profile (id, tenant_id, display_name, app_role) values
  ('f0000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Buyer Default',          'buyer'),
  ('f0000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Seller Default',         'seller'),
  ('f0000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Catalog Editor Default', 'catalog_editor'),
  ('f0000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Admin Default',          'admin'),
  ('f0000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000002', 'Buyer Client A',         'buyer'),
  ('f0000001-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'Moderator Default',      'moderator');

reset role;
