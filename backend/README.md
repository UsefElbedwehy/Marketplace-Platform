# Backend

Supabase project (Postgres/Auth/Storage/Realtime/RLS) as the data plane, with a Backend-for-Frontend implemented as Edge Functions exposing the versioned REST contract. See [docs/BACKEND.md](../docs/BACKEND.md) and [docs/planning/03-backend-architecture.md](../docs/planning/03-backend-architecture.md).

## Local development

Requires the [Supabase CLI](https://supabase.com/docs/guides/local-development) (already configured here via `supabase init` — see `supabase/config.toml`) **and Docker** (Docker Desktop, Colima, or OrbStack) — the CLI runs Postgres/Auth/Storage/Realtime as local containers.

```bash
supabase start        # from backend/ — boots the local stack
supabase db reset      # applies migrations/ then seeds from seed/*.sql
supabase stop
```

**Status note (Phase 0):** this session set up `supabase/config.toml` (project id, seed path, anonymous sign-ins for guest browsing per [ADR-0007](../docs/adr/0007-authentication.md)) and the directory scaffolding (`migrations/`, `functions/_shared/`, `seed/`, `policies/`), but could not run `supabase start` in this environment because **Docker is not installed here**. Docker Desktop is a heavier install than the CLI tools set up so far (a virtualization layer + system extensions), so it was left for whoever sets up local development to install deliberately rather than installed unprompted. Before Phase 1 work begins, install Docker and confirm `supabase start` boots cleanly.

## Structure

| Path | Contents |
|---|---|
| `supabase/config.toml` | Local dev stack configuration (ports, auth, seed paths, …) |
| `supabase/migrations/` | Versioned SQL migrations (empty until Phase 1) |
| `supabase/functions/` | Edge Functions — the BFF (empty until Phase 1) |
| `supabase/seed/` | Seed SQL applied after migrations on `db reset` |
| `supabase/policies/` | RLS policy documentation (statements live in migrations) |
| `src/` | Shared Deno/TS domain code used by functions |
| `tests/` | Contract-conformance + integration tests |
