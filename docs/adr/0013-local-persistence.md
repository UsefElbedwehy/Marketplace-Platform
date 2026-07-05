# ADR-0013 — SwiftData as offline cache, not source of truth

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The app needs offline support for config, theme, category/attribute metadata, and recently viewed listings. The backend is always the source of truth (foundation hard rule). We need local persistence that fits iOS 17+, Swift Concurrency, and the modular architecture.

## Decision
Use **SwiftData** as an **offline read cache** only — never authoritative. All cache access is behind **repository protocols** in `DataKit`, so the store is swappable. Cache policies vary by data type (cache-then-network for config/theme/schema, network-first for feeds); invalidation is version/ETag-driven. Sessions/tokens live in **Keychain**, not SwiftData.

## Alternatives considered
- **Core Data:** mature and powerful, but more boilerplate and less ergonomic with Swift Concurrency for a greenfield iOS-17 app.
- **GRDB/SQLite:** great control and query power, but manual mapping and more surface to own.
- **Plain file/JSON cache:** simplest, but no querying for cached feeds/detail.

## Consequences
- (+) Native iOS-17 integration, `@Model` ergonomics, concurrency-friendly.
- (+) Behind repositories → swappable if SwiftData limits bite (a real possibility for a young framework).
- (−) SwiftData is relatively new; some rough edges. Mitigated by the repository indirection and cache-only role (low blast radius).
