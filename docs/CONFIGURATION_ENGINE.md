# Configuration Engine

> Living document. Full design: [planning/07-configuration-whitelabel-theme.md](planning/07-configuration-whitelabel-theme.md).

The Development Schema is the versioned, backend-compatible source of truth for what an app is. `configs/{default,clients/*}` merge deterministically and validate against `contract/schema/*.schema.json` in CI. See [ADR-0004](adr/0004-configuration-engine.md).

**Status:** the full runtime lifecycle is implemented and verified — `config.bundle`/`config.theme` tables store versioned documents (seeded from the validated `configs/` tree), `GET/PATCH /v1/config` and `/v1/theme` serve and publish them with ETag caching, and the dashboard's **Config Studio** and **Theme Studio** edit them live (verified in a real browser: toggling a module flag and publishing a new theme color both persisted correctly and were re-verified via direct Postgres queries).

Not yet built: the client-side `Configuration` module (iOS, Phase 3 — deprioritized this session) and the iOS white-label *build* pipeline (Phase 5, blocked on Phase 3/4).
