# ADR-0003 — Dynamic Category & Attribute Engine = hybrid model

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The platform is a general classified marketplace whose listing structure (categories, subcategories, per-subcategory attribute schemas, field types, validation, dependencies, localization) is **defined in the dashboard at runtime**, not in code. Clients render forms/filters from metadata. The store must support flexible, admin-defined schemas **and** fast attribute filtering (e.g., "BMW, 2018–2022, <100k km, automatic") over large listing volumes. This is the platform's core technical risk.

## Decision
A **hybrid model**:
1. **Normalized definition tables** (`category`, `attribute_group`, `attribute`, `attribute_option`, `attribute_dependency`) — first-class, dashboard-edited, versioned, i18n.
2. **Typed value store** (`listing_attribute_value` with `value_text/number/bool/date/option_id/option_ids/json`, PK `(listing_id, attribute_id)`) — integrity + indexable, no all-text casting.
3. **Denormalized JSONB projection** (`listing.attributes_index`) kept in sync by trigger — flexible GIN-indexed filtering + single-read hydration.
4. **Generated columns + btree** for hot, high-traffic filterable attributes; **FTS `tsvector`** for text search.
5. Search moves to an **external engine (Meilisearch/Typesense/OpenSearch) behind the same `/v1/listings` contract** when Postgres strains.

## Alternatives considered
- **Pure EAV (tall all-text value table):** maximal write flexibility, but filtering becomes cast-heavy and slow; weak typing/integrity. Rejected — the classic path to an unqueryable platform.
- **Pure JSONB blob on `listing`:** simple, GIN helps filtering, but weak per-field typing/constraints and awkward validation. Rejected as the *sole* store; adopted only as the projection layer.

## Consequences
- (+) Write-flexible (admins define anything) **and** read-performant (typed + indexed + projection).
- (+) Type integrity enforced by DB triggers against attribute definitions.
- (−) Write path maintains two representations (typed rows + JSONB projection) via triggers — more moving parts. Accepted for the query performance it buys.
- (−) Requires disciplined indexing and a benchmark gate ([roadmap P2](../planning/11-roadmap.md#phase-2)).
