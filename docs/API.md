# API

> Living document. Full strategy: [planning/08-api-auth.md](planning/08-api-auth.md).

Contract-first REST, versioned (`/v1`), spec of record at [`contract/openapi/v1/`](../contract/openapi/v1/). Standard success/error envelopes, cursor pagination, ETag caching. See [ADR-0006](adr/0006-api-contract.md).

**Status:** implemented and verified: `GET/PATCH /v1/config`, `GET/PATCH /v1/theme`, `GET /v1/categories/tree`, `GET/POST /v1/categories/{id}/schema` + `attribute-groups`, `POST /v1/attribute-groups/{id}/attributes`, `GET/POST /v1/attributes/{id}/options` + `/dependencies`, `GET/POST /v1/listings`, `GET/PATCH /v1/listings/{id}`, `GET /v1/users`, `PATCH /v1/users/{id}`. Auth (`v1-auth`, real GoTrue-backed flows) is not yet implemented — see [ADR-0007](adr/0007-authentication.md) and the roadmap.

## Endpoint groups

| Group | Endpoints | Notes |
|---|---|---|
| `system` | `GET /v1/health` | |
| `config` | `GET/PATCH /v1/config` | PATCH is the Config Studio's publish path, RLS-gated to admins |
| `theme` | `GET/PATCH /v1/theme` | Same pattern as config |
| `catalog` ⭐ | `GET /v1/categories/tree`, `GET /v1/categories/{id}/schema`, `GET/POST /v1/attributes/{id}/options`, plus write routes for categories/attribute-groups/attributes/dependencies | The Dynamic Category & Attribute Engine's contract |
| `listings` ⭐ | `GET/POST /v1/listings`, `GET/PATCH /v1/listings/{id}` | Filter compiles against `attributes_index`; create validates against the category's schema; `GET /v1/listings/{id}` is the schema-projected detail view (RLS-gated, resolves to 404 rather than leaking existence via 403); PATCH runs the moderation status state machine (`backend/src/listing_service.ts`'s `updateListingStatus`) — RLS gates row access, the service gates which transitions are legal and which require a moderator |
| `users` | `GET /v1/users`, `PATCH /v1/users/{userId}` | Admin-only (`app_role in (admin, super_admin)`). `PATCH` changes another tenant member's `app_role`; RLS (`profile_update_admin`) gates row access, `backend/src/user_service.ts`'s `updateUserRole` additionally forbids an actor ever changing their own role — enforced at both the RLS/trigger layer and this app layer (defense in depth) |

`contract/openapi/v1/openapi.yaml` is the source of record; `packages/contract-types` generates the TypeScript the dashboard consumes (`ApiPaths`/`ApiComponents`) — see `dashboard/src/lib/contract-types.ts`.
