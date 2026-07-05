-- LOCAL DEV / TESTING FIXTURES ONLY — NOT reference marketplace data.
--
-- A handful of ready-to-use identities (one per app_role) so v1-dev-auth
-- (backend/supabase/functions/v1-dev-auth — itself dev-only, see its header)
-- has something real to mint tokens for. Before ever pointing sql_paths at a
-- real staging/production Supabase project, exclude this file — it exists
-- only because there is no GoTrue/Docker in this environment to create real
-- users through (see backend/README.md).

set role service_role;

insert into auth.users (id, email) values
  ('90000001-0000-0000-0000-000000000001', 'buyer@dev.local'),
  ('90000001-0000-0000-0000-000000000002', 'seller@dev.local'),
  ('90000001-0000-0000-0000-000000000003', 'catalogeditor@dev.local'),
  ('90000001-0000-0000-0000-000000000004', 'admin@dev.local'),
  ('90000001-0000-0000-0000-000000000005', 'moderator@dev.local')
on conflict (id) do nothing;

insert into identity.profile (id, tenant_id, display_name, app_role) values
  ('90000001-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Dev Buyer',          'buyer'),
  ('90000001-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Dev Seller',         'seller'),
  ('90000001-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Dev Catalog Editor', 'catalog_editor'),
  ('90000001-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Dev Admin',          'admin'),
  ('90000001-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Dev Moderator',      'moderator')
on conflict (id) do nothing;

reset role;
