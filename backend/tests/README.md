# Backend tests

## `sql/` — RLS + trigger verification suite

Runs against a real local Postgres (`marketplace_platform_test`, kept separate from the dev DB) — no Docker needed for this layer, since it exercises the database directly. Run it with:

```bash
backend/scripts/run-rls-tests.sh
```

A dependency-free test harness (`000_test_harness.sql` — no pgTAP install required) provides `test.assert_succeeds`/`test.assert_raises`/`test.assert_count`/`test.assert_true` plus `test.act_as(sub, tenant, app_role)` / `test.act_as_anon()` / `test.act_as_service()` session-simulation helpers that switch the Postgres role and set the same `request.jwt.claims` GUC PostgREST would set from a real decoded JWT. `999_report.sql` prints every result and raises (non-zero exit) if anything failed, so the script is CI-usable, not just readable.

41 assertions across identity/config/catalog/listing, covering: self-edit vs. privilege-escalation (blocked by a trigger, not RLS — RLS restricts rows, not columns), admin-vs-self role management (an admin can change another user's role but never their own; `tenant_id` stays service_role-only even for admins), tenant isolation, public vs. owner vs. moderator listing visibility, the attribute type-enforcement trigger (rejects wrong `value_*` column, enforces `validation` min/max), the `attributes_index` JSONB sync (including option-id-to-scalar-value resolution), and the dependent-options pattern (Model filtered by Brand).

**A note on what "blocked" looks like:** an `INSERT` (or a `GRANT`-level denial) that RLS/privileges reject **raises** an exception. An `UPDATE`/`DELETE` blocked by a policy's `USING` clause does **not** raise — the row is simply invisible to the statement, so it silently affects 0 rows. Two tests in this suite were originally written the wrong way around (`assert_raises` on an UPDATE) and had to be fixed once real runs showed a false failure — see git history on `030_config_tests.sql` / `050_listing_tests.sql` if that distinction ever needs re-explaining.

## Contract-conformance tests

Backend responses validated against `contract/openapi` + `contract/examples`. **Status:** not yet implemented — lands with the Edge Functions in this phase (see `backend/supabase/functions/*/README.md` once those exist) since it needs the HTTP layer, not just the DB.
