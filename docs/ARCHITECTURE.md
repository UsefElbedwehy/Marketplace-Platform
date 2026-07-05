# Architecture

> **Living document.** Updated as each roadmap phase lands. Full rationale and alternatives live in [docs/planning](planning/README.md) and [docs/adr](adr/README.md) — this file is the current-state summary.

## Current implementation status

**Phase 0, Phase 1, and Phase 2 (the Dynamic Category & Attribute Engine ⭐) are complete**, plus the dashboard portion of Phase 5 (Schema Builder, Config Studio, Theme Studio). iOS (Phase 3/4) was explicitly deprioritized this session in favor of backend + dashboard depth. See [ROADMAP.md](ROADMAP.md) for the full breakdown and how Phase 1/2 were verified without Docker.

## Summary

The platform is three engines (Configuration/White-Label, Theme, Dynamic Category & Attribute) sitting behind a single versioned REST contract, consumed by iOS, the admin dashboard, and future Android/Web clients. Supabase is the data plane; a Backend-for-Frontend implemented as Supabase Edge Functions is the application plane clients actually depend on. All three engines' backend and dashboard halves are implemented and verified end-to-end against real Postgres.

For the full high-level architecture, module boundaries, and dependency graph, see [planning/01-system-architecture.md](planning/01-system-architecture.md).

## Repository map

| Path | Purpose | Detail |
|---|---|---|
| `contract/` | OpenAPI spec + JSON Schema — the platform-neutral source of truth | [API.md](API.md) |
| `configs/` | Development Schemas (default + per-client + per-env) | [CONFIGURATION_ENGINE.md](CONFIGURATION_ENGINE.md) |
| `ios/` | SwiftUI app, SPM modules — not yet started | [IOS_ARCHITECTURE.md](IOS_ARCHITECTURE.md) |
| `backend/` | Supabase migrations, RLS, Edge Functions — DB + API layers implemented | [BACKEND.md](BACKEND.md), [DATABASE.md](DATABASE.md) |
| `dashboard/` | Next.js admin CMS — Schema Builder/Config Studio/Theme Studio implemented | [planning/06-dashboard-architecture.md](planning/06-dashboard-architecture.md) |
| `packages/` | Shared TS: contract types, config validation | — |
| `tooling/` | White-label build pipeline, lint scripts, codegen | [WHITE_LABEL.md](WHITE_LABEL.md) |
| `docs/adr/` | Architecture Decision Records | [adr/README.md](adr/README.md) |

## Architectural rules enforced by CI

1. No `import Supabase` outside `ios/Packages/Networking`.
2. No raw color/font literals outside `ios/Packages/DesignSystem`.
3. No `Features/X` importing `Features/Y` directly.
4. Every `configs/**` document validates against `contract/schema/*.schema.json`.
5. Every OpenAPI change is checked against `contract/examples` fixtures.

See [ADR-0014](adr/0014-ci-cd.md) for why these are executable, not aspirational. (Backend/dashboard equivalents — the RLS test suite, Deno unit tests, `tsc --strict` on generated types — exist but are not yet wired into `.github/workflows/ci.yml`, since that requires a Postgres+Deno CI runner image; tracked as follow-up.)
