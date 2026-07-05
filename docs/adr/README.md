# Architecture Decision Records (ADRs)

An ADR captures **one significant decision**: its context, the options considered, the choice, and the consequences. They are immutable once accepted — a reversal is a *new* ADR that supersedes the old one. This keeps the "why" discoverable for future engineers and AI agents.

**Format:** [MADR](https://adr.github.io/madr/)-style — Status · Context · Decision · Alternatives · Consequences.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-clean-architecture-ios.md) | Clean Architecture + MVVM-C on iOS | Accepted |
| [0002](0002-backend-bff-edge-functions.md) | Backend boundary = BFF via Supabase Edge Functions | Accepted |
| [0003](0003-dynamic-attribute-engine.md) | Dynamic Category & Attribute Engine = hybrid model | Accepted |
| [0004](0004-configuration-engine.md) | Configuration Engine + versioned Development Schema (build-time vs runtime) | Accepted |
| [0005](0005-theme-engine.md) | Semantic token Theme Engine, runtime-driven | Accepted |
| [0006](0006-api-contract.md) | Contract-first REST + OpenAPI, versioned | Accepted |
| [0007](0007-authentication.md) | Wrapped Supabase Auth behind `/v1/auth` contract | Accepted |
| [0008](0008-feature-flags.md) | Backend-driven, typed feature flags | Accepted |
| [0009](0009-monorepo.md) | Monorepo with path-scoped boundaries | Accepted |
| [0010](0010-dashboard-nextjs.md) | Admin dashboard on Next.js (App Router) | Accepted |
| [0011](0011-multi-tenancy.md) | Single-tenant-per-deployment, schema tenant-aware | Accepted |
| [0012](0012-dependency-injection.md) | Factory for iOS dependency injection | Accepted |
| [0013](0013-local-persistence.md) | SwiftData as offline cache, not source of truth | Accepted |
| [0014](0014-ci-cd.md) | Path-scoped monorepo CI/CD with executable boundary rules | Accepted |
| [0015](0015-ios-modularization.md) | Swift Package Manager per-module modularization | Accepted |

> These decisions were made during the planning session and are **pending user approval** before implementation. They become "Accepted" on approval; until then treat them as proposed.
