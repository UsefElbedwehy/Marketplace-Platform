# Edge Functions

The Backend-for-Frontend ([ADR-0002](../../../docs/adr/0002-backend-bff-edge-functions.md)): each directory here is one deployable Supabase Edge Function, implementing a slice of `contract/openapi/v1/openapi.yaml`.

| Function | Endpoint(s) | Status |
|---|---|---|
| `v1-config` | `GET /v1/config` | ✅ implemented, tested |
| `v1-theme` | `GET /v1/theme` | ✅ implemented, tested |
| `v1-catalog` | `GET /v1/categories/tree`, `GET /v1/categories/{id}/schema`, `GET /v1/attributes/{id}/options` ⭐ | ✅ implemented, tested |
| `v1-listings` | `POST /v1/listings`, `GET /v1/listings`, `PATCH /v1/listings/{id}` ⭐ | ✅ implemented, tested |
| `v1-users` | `GET /v1/users`, `PATCH /v1/users/{id}` | ✅ implemented, tested — admin-only |
| `v1-dev-auth` | `POST /v1/dev-auth` | ⚠️ **local dev only** — see below |
| `_shared` | auth/db/error/http glue used by all of the above | — |

## Business logic lives in `backend/src/`, not here

Each `<function>/index.ts` is a thin HTTP handler: parse the request, call a service in `backend/src/`, shape the response. The services (`config_service.ts`, `catalog_service.ts`, `listing_service.ts`) are the portable part — they depend only on a structural `QueryExecutor` interface (`backend/src/query_executor.ts`), not on Deno, Supabase, or HTTP. That's what `deno test` exercises with mocked executors, and what would move unchanged if the BFF were ever re-hosted (ADR-0002).

## Running locally (no Docker)

There is no Docker in this environment, so `supabase functions serve` (which runs the Edge Runtime in a container) isn't available — see [backend/README.md](../../README.md). Instead:

```bash
cd backend
deno task serve   # scripts/serve-local.ts — combines every handler above behind one process on :8000
```

`_shared/db.ts` connects **directly** to the local Postgres and reproduces PostgREST's per-request behavior itself (`SET LOCAL ROLE`, `SET LOCAL request.jwt.claims`) before running any query — so RLS applies exactly as it would in production, without needing PostgREST/GoTrue running. A real deployment swaps this one file's internals for `@supabase/supabase-js` against PostgREST; no call site changes (see `_shared/db.ts`'s own header comment).

**Verified this way, against real seeded Postgres data:** config/theme fetch with ETag/304, the full category tree, a composed Cars schema (with i18n locale resolution and dependent Brand→Model options), creating a listing with field-level validation errors, draft-vs-published visibility, JSONB attribute filtering (`brand=bmw AND mileage<100000`), the full moderation loop (submit for review → self-approval blocked with 403 → moderator's queue shows it → approve → publicly visible), and admin role management (an admin promotes another user, a self-role-change attempt is rejected with 403, a non-admin's `/v1/users` request is rejected with 403) — driven live from the dashboard in a real browser.

## `v1-dev-auth` is not part of the contract

It mints a locally-signed JWT (HS256, a hardcoded dev secret) with the claims shape (`sub`, `role`, `tenant_id`, `app_role`) our RLS policies read — a stand-in for real Supabase Auth (GoTrue), which isn't reachable without Docker. It is **absent from `contract/openapi`** deliberately and must never be deployed to a real project. Real auth (email/OTP/Apple/Google via wrapped Supabase Auth, per [ADR-0007](../../../docs/adr/0007-authentication.md)) is unimplemented Phase 1 roadmap work.

## Contract-conformance tests

Not yet implemented — the unit tests in `backend/src/*.test.ts` cover business logic with mocked repositories; a suite asserting live HTTP responses conform to `contract/openapi` + `contract/examples` is the next layer (see [backend/tests/README.md](../../tests/README.md)).
