# ADR-0006 — Contract-first REST + OpenAPI, versioned

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
Three+ clients (iOS, dashboard, future Android/Web) must share one stable, portable API. The contract must be consumable from Swift and TypeScript, cache-friendly, and re-hostable on any backend.

## Decision
**Contract-first REST/JSON** with an **OpenAPI 3.1 spec** in `contract/openapi/v1/` as the source of truth. URL-prefixed versioning (`/v1`). Client DTOs (Swift) and TS types are generated from / validated against the spec; server request validation (zod) is derived from it. Uniform conventions: cursor pagination for feeds, standard success/error envelopes, ETag caching for config/theme/schema, idempotency keys on creating/charging POSTs, correlation ids. A shared `contract/examples` fixture set drives consumer + provider conformance tests.

## Alternatives considered
- **GraphQL:** flexible client queries (appealing for dynamic schemas), but heavier server, caching complexity, and client weight. Rejected for v1; composed-schema REST endpoints already deliver tailored payloads. Can be added later as an additive gateway.
- **gRPC:** great typing/perf, poor browser/dashboard and Edge-Function fit. Rejected.
- **Code-first (generate spec from handlers):** rejected — contract-first keeps the contract stable and platform-neutral, decoupled from the current Edge Function implementation.

## Consequences
- (+) One reviewed, versioned contract; generated bindings prevent drift; easy re-host.
- (+) Conformance tests keep three platforms honest against one spec.
- (−) Spec authoring discipline + codegen tooling to maintain. Accepted.
