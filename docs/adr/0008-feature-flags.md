# ADR-0008 — Backend-driven, typed feature flags

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
Modules/capabilities must be enable-able per client and environment (and later per user segment), and shipped features need kill-switches and gradual rollout — all without code changes.

## Decision
Feature flags are part of the **runtime config**, delivered in the boot config bundle. Flag keys are **typed** (an enum generated from `contract/schema`) so referencing an unknown flag is a compile error. Two kinds: **capability flags** (mount a module/tab, expose endpoints) and **operational flags** (kill-switch/rollout). Scoped per tenant/client and environment now; user-segment targeting later. Evaluated server-side; clients read cached values with safe offline defaults; critical kill-switches can refresh eagerly. Flags are owned, documented, and have a removal plan.

## Alternatives considered
- **Third-party flag service (LaunchDarkly/ConfigCat):** powerful targeting/analytics, but another vendor + cost; flags are naturally part of our backend-driven config. Deferred behind a `FeatureFlags` port so adoption later is a swap.
- **Compile-time flags / build variants:** rejected — can't toggle without a release; defeats runtime configurability.

## Consequences
- (+) Per-client capability composition and safe rollout with no release.
- (+) Typed keys prevent stringly-typed flag bugs.
- (−) Risk of permanent flag debt → mitigated by ownership + removal discipline.
