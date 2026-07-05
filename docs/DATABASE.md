# Database

> Living document. Full schema design: [planning/04-database-architecture.md](planning/04-database-architecture.md). The flagship dynamic attribute store: [planning/05-dynamic-schema-engine.md](planning/05-dynamic-schema-engine.md).

Postgres via Supabase, schemas grouped by bounded context. RLS on every table, deny-by-default. Tenancy: single-tenant-per-deployment, schema tenant-aware ([ADR-0011](adr/0011-multi-tenancy.md)).

**Status:** `platform`, `identity`, `config`, `catalog` ⭐, and `listing` ⭐ schemas are implemented (`backend/supabase/migrations/`) and verified against real local Postgres (`social`, `commerce`, `moderation` are not yet built — Phase 6/7 territory).

| Schema | Contents | Migration |
|---|---|---|
| `auth` (stub) | Local-only mirror of Supabase's real `auth.users`/`uid()`/`role()`/`jwt()` — see the migration's own header for why | `20260704060802_extensions_and_auth_stub.sql` |
| `platform` | `tenant`, immutable `audit_log` | `20260704060900_platform_schema.sql` |
| `identity` | `profile` (role/tenant assignment), `custom_access_token_hook` | `20260704061000_identity_schema.sql` |
| `config` | Versioned `bundle`/`theme` documents, one active row per tenant | `20260704061100_config_schema.sql` |
| `catalog` ⭐ | `category` (self-ref tree), `attribute_group`, `attribute`, `attribute_option`, `attribute_dependency` | `20260704061200_catalog_schema.sql` |
| `listing` ⭐ | `listing`, `listing_attribute_value` (typed, hybrid store), `listing_media` | `20260704061300_listing_schema.sql` |

## The hybrid attribute value store, verified

`listing.listing_attribute_value` stores typed columns (`value_text`/`value_number`/`value_option_id`/…); a trigger (`listing.enforce_attribute_value_type`) rejects any row where the wrong column is populated for the attribute's `data_type`, and enforces `validation` (min/max/length/pattern) from `catalog.attribute`. A second trigger (`listing.sync_attributes_index`) keeps a denormalized JSONB projection (`listing.attributes_index`) in sync, resolving option ids to their scalar `value` — this is what `GET /v1/listings` filters against (`attributes_index @> '{"brand":"bmw"}'`). See [ADR-0003](adr/0003-dynamic-attribute-engine.md).

## Local development (no Docker)

`backend/scripts/local-db-reset.sh` drops/recreates a local Postgres database and applies every migration + seed file in order — the same effective sequence `supabase db reset` would run, but against a plain Homebrew Postgres (installed this session; see [backend/README.md](../backend/README.md)) rather than the Docker-based Supabase stack.

## RLS/trigger test suite

`backend/tests/sql/` — a from-scratch, dependency-free test harness (no pgTAP) exercising 27 real assertions against a dedicated `marketplace_platform_test` database via `backend/scripts/run-rls-tests.sh`: self-edit vs. privilege escalation (blocked by trigger — RLS restricts rows, not columns), tenant isolation, public/owner/moderator listing visibility, attribute type enforcement, and the dependent-options pattern. See [backend/tests/README.md](../backend/tests/README.md).
