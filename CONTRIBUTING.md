# Contributing

## Before you start
Read [docs/planning/README.md](docs/planning/README.md) and the relevant [ADRs](docs/adr/README.md). Architectural decisions are recorded there — don't relitigate them in a PR; open a new ADR proposing a change instead.

## Repository rules (enforced by CI)

- **No `import Supabase` outside `ios/Packages/Networking`.** The app never depends on Supabase directly — see [ADR-0002](docs/adr/0002-backend-bff-edge-functions.md).
- **No raw color/font literals outside `ios/Packages/DesignSystem`.** Use semantic theme tokens — see [ADR-0005](docs/adr/0005-theme-engine.md).
- **No `Features/X` importing `Features/Y`.** Cross-feature interaction goes through `DomainKit` or the coordinator — see [planning/01 §4](docs/planning/01-system-architecture.md#4-module-boundaries--dependency-rules).
- **Every `configs/**` file must validate** against `contract/schema/*.schema.json` (`npm run validate --workspace=packages/config-validation`).
- **Every feature module ships its doc set** (`README.md`, `Architecture.md`, `Flow.md`, `API.md`, `Testing.md`, `Future.md`) — see [planning/09 — Documentation strategy](docs/planning/09-cross-cutting.md#documentation-strategy).

## Definition of Done

A change isn't done until: exit criteria for its phase are demoed, tests pass at the documented target, module/ADR/roadmap docs are updated in the same PR, boundary + contract lints are green, and `CHANGELOG.md` is updated.

## Commit style

Small, reviewable commits. Reference the roadmap phase or ADR a change belongs to when relevant.
