# System Design

> Living document. Full design + diagrams: [planning/01-system-architecture.md](planning/01-system-architecture.md).

Four planes — Clients (iOS/Android/Web/Dashboard) → BFF contract (versioned REST, Edge Functions) → Data plane (Supabase) → Provider plane (payments/maps/push/analytics). See the planning doc for sequence diagrams (boot flow, create-listing flow) and the end-to-end dependency graph.

**Status:** Phase 0 — contract and config scaffolding in progress. No runtime system exists yet.
