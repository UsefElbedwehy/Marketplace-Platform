# Backend

> Living document. Full architecture: [planning/03-backend-architecture.md](planning/03-backend-architecture.md).

Supabase (Postgres/Auth/Storage/Realtime/RLS) as data plane; a Backend-for-Frontend implemented as Supabase Edge Functions exposes the versioned REST contract clients depend on. See [ADR-0002](adr/0002-backend-bff-edge-functions.md).

**Status:** `v1-config`, `v1-theme`, `v1-catalog` ⭐, and `v1-listings` ⭐ are implemented and verified end-to-end (real HTTP → real Postgres, no mocks) — see [backend/supabase/functions/README.md](../backend/supabase/functions/README.md) for the full endpoint table and how local verification works without Docker.

## Structure

- **`backend/src/`** — portable business logic (`config_service.ts`, `catalog_service.ts`, `listing_service.ts`), depending only on a structural `QueryExecutor` interface, not Deno/HTTP/Postgres specifics. Unit-tested with mocked executors (16 tests, `deno task test`).
- **`backend/supabase/functions/_shared/`** — Edge-Function-runtime glue: `db.ts` (the local Postgres adapter reproducing PostgREST's per-request role/claims behavior), `auth.ts` (JWT verify/mint), `errors.ts`/`http.ts`/`etag.ts`.
- **`backend/supabase/functions/v1-*/`** — thin HTTP handlers wiring the two together.

## Local development (no Docker)

```bash
cd backend
deno task serve   # scripts/serve-local.ts — every function behind one process on :8000
deno task test    # unit tests, mocked repositories
```

`_shared/db.ts` connects directly to the local Postgres and performs `SET LOCAL ROLE` / `SET LOCAL request.jwt.claims` itself before running any query, so RLS applies exactly as it would via a real PostgREST-fronted deployment. A real deployment swaps this one file's internals for `@supabase/supabase-js`; no other call site changes. `v1-dev-auth` mints local JWTs in place of GoTrue and is deliberately excluded from `contract/openapi`.

## What's proven vs. what isn't

Proven: config/theme fetch + publish with ETag caching, the full category tree, composed per-category schemas (with i18n and dependent-option filtering), listing creation with field-level validation, draft/published visibility, and JSONB attribute filtering — all against real seeded data, plus driven live from the [dashboard](../dashboard) in a browser.

Not yet proven: the actual Supabase Edge Runtime (Docker) and real GoTrue-issued JWTs. See [docs/ROADMAP.md](ROADMAP.md#phase-1--2--how-they-were-verified-without-docker).
