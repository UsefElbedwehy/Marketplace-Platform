# Testing

> Living document. Full strategy: [planning/09-cross-cutting.md — Testing strategy](planning/09-cross-cutting.md#testing-strategy).

Test pyramid weighted to fast domain/unit tests, with targeted integration/contract/snapshot coverage where risk concentrates: the dynamic schema engine, the theme engine, and the API contract. Coverage floors: domain/use-case ≥85%, RLS 100% positive+negative, contract endpoints 100% conformance.

**Status:** Phase 0 — `packages/config-validation` has schema-validation tests; CI runs them on every config change. Domain/RLS/snapshot suites land alongside their respective phases.
