# Contract

The platform-neutral source of truth. Every client (iOS, Android, Web, Dashboard) and the backend itself are validated against what's here — nothing else.

- **`openapi/v1/openapi.yaml`** — the REST API contract of record (OpenAPI 3.1). See [ADR-0006](../docs/adr/0006-api-contract.md).
- **`schema/`** — JSON Schema for the Development Schema: `common.schema.json` (shared defs), `app.schema.json` (build-time slice), `config.schema.json` (runtime slice), `theme.schema.json` (Theme Engine tokens). See [ADR-0004](../docs/adr/0004-configuration-engine.md) and [ADR-0005](../docs/adr/0005-theme-engine.md).
- **`examples/`** — canonical fixtures used by both consumer tests (iOS/dashboard decode these) and provider tests (backend responses conform to these). Keeps three platforms honest against one contract.

## Development Schema merge model

Three files per client: `app.json` (build-time), `config.json` (runtime), `theme.json` (runtime).

| File | Merge behavior | Why |
|---|---|---|
| `app.json` | **Not merged.** Each client supplies a complete, valid document. | Build identity (bundle id, URL scheme, entitlements) must never be implicit — inheriting it risks shipping the wrong binary identity. |
| `config.json` | **Deep-merged**: `clients/default/config.json` ← `clients/<client>/config.json` (partial overlay) ← `<env>/config.json` (partial overlay, highest precedence). | Runtime behavior should default sensibly; clients/environments only specify what differs. |
| `theme.json` | **Deep-merged**, same order as `config.json`, recursively (a client can override a single color token without restating all 28). | Same rationale — white-label re-skinning should be a diff, not a fork. |

Validation (`packages/config-validation`):
- `default/*.json` must satisfy the **full** JSON Schema (all required fields present).
- Client/env overlay files are validated against a **structurally-derived partial schema** (same type/enum/format/`additionalProperties` constraints, `required` stripped recursively) — catches typos and wrong types without demanding completeness.
- The **effective merged config** (default + client + env) is validated against the full schema — this is the document the backend actually serves.
