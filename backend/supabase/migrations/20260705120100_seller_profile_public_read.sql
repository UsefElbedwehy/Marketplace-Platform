-- Seller profiles need to be publicly readable (Phase 6 exit criterion:
-- "view a seller profile"). identity.profile's existing RLS
-- (profile_select_own_or_admin, migration 20260704061000) only lets a user
-- read their own row or an admin read their tenant's — too narrow for a
-- buyer viewing a seller they've never interacted with as an admin.
--
-- backend/src/seller_profile_service.ts only ever selects the public-safe
-- columns (display_name, avatar_url, bio, created_at, rating_count,
-- rating_sum) and never app_role/tenant_id, so widening SELECT here is safe:
-- clients never query Postgres directly (ADR-0002), only through Edge
-- Functions that shape the response — v1-users' admin-only fields stay
-- gated by that function's own requireAdmin() check regardless of what RLS
-- additionally permits. Postgres combines multiple permissive policies for
-- the same command with OR, so this purely widens visibility alongside the
-- existing policy rather than replacing it.

create policy profile_select_public on identity.profile
  for select
  using (tenant_id = platform.current_tenant_id() or platform.current_tenant_id() is null);
