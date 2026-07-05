# ADR-0009 — Monorepo with path-scoped boundaries

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The platform spans a shared contract, shared config schemas, iOS, backend, and a dashboard, all of which must evolve together and stay consistent. We need one source of truth for the contract and the ability to make atomic cross-cutting changes, while keeping strict module boundaries.

## Decision
A **single monorepo** with **path-scoped** top-level areas: `contract/`, `configs/`, `ios/`, `backend/`, `dashboard/`, `packages/` (shared TS), `tooling/`, `docs/`. The **contract and configs sit above the platform folders** as shared truth; each platform generates its bindings from them. CI runs **path-scoped jobs** (only affected areas build/test) and enforces boundaries as executable lint rules.

## Alternatives considered
- **Polyrepo (repo per platform + a contract repo):** clean ownership, independent release cadence. Rejected for v1 — cross-cutting contract/config changes become multi-repo choreography with version-skew risk; worse for a small team and for AI-agent navigation.
- **Monorepo with a heavy build system (Bazel/Nx across native+web):** powerful, but high setup cost and native-iOS friction. Rejected — path-scoped CI achieves most of the benefit at a fraction of the complexity.

## Consequences
- (+) One place for contract truth; atomic changes; simpler onboarding for humans and AI.
- (+) Boundaries enforced in CI (import/color/feature lints).
- (−) Repo grows large; needs path-scoped CI + clear CODEOWNERS. Accepted.
