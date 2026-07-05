-- Fixes a real bug caught via live curl verification: an anonymous caller
-- viewing GET /v1/profiles/{id} got a 403 even though migration
-- 20260705120100's profile_select_public RLS policy correctly permits it
-- (platform.current_tenant_id() is null for anon, satisfying that policy's
-- `or ... is null` clause). The actual failure was a raw GRANT error, not an
-- RLS violation: identity.profile's original migration only ever granted
-- SELECT to `authenticated` (and service_role), never to `anon` — a table-
-- level privilege gap RLS can't paper over, same class of bug as the
-- favorites upsert grant fix (20260705120400).

grant select on identity.profile to anon;
