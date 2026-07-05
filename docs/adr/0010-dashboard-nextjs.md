# ADR-0010 — Admin dashboard on Next.js (App Router)

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The dashboard is the control room and the **source of truth for marketplace structure**. Its centerpiece is a bespoke **Schema Builder** (drag-and-drop category tree, attribute/option/dependency editors, live form preview) plus Config/Theme studios. It must consume the same REST contract as the apps and be maintainable for years.

## Decision
Build the dashboard with **Next.js (App Router) + TypeScript + React**, consuming the **shared `/v1` contract** (admin-scoped endpoints) and the generated `contract-types`. The Schema Builder's live preview reuses the **same schema contract the app renders**, guaranteeing fidelity.

## Alternatives considered
- **Admin-scaffold frameworks (Refine/React-Admin):** fast CRUD, but fight the bespoke builder/preview tooling that dominates this app. Rejected as the primary framework (patterns may be borrowed for plain CRUD screens).
- **Vue/Nuxt or SvelteKit:** viable; React chosen for the deepest ecosystem for complex builder UIs (dnd, form engines) and the widest hiring/AI familiarity.
- **Native macOS/SwiftUI admin:** rejected — no web reach, install friction, cross-platform admins.

## Consequences
- (+) Same contract as apps → preview fidelity, contract battle-tested by two consumers.
- (+) Rich ecosystem for the builder; SSR/RSC where useful.
- (−) A second language/runtime (TS/React) alongside Swift — mitigated by shared contract types and docs.
