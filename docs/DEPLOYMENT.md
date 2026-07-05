# Deployment

> Living document. Full CI/CD strategy: [planning/09-cross-cutting.md — CI/CD strategy](planning/09-cross-cutting.md#cicd-strategy), [ADR-0014](adr/0014-ci-cd.md).

Path-scoped monorepo CI; backend migrations + Edge Functions deploy to staging then production behind manual approval; iOS via Fastlane lanes per client/environment (white-label pipeline); dashboard via standard web deploy.

**Status:** Phase 0 complete — CI pipeline (`.github/workflows/ci.yml`) runs contract/config validation, contract-types generate+typecheck+drift-check, boundary lints, and unit tests on every push/PR. Deployment lanes (Fastlane, Supabase CD, dashboard hosting) land per-phase as their subjects are implemented.
