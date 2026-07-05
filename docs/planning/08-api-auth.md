# 08 — API & Authentication Strategy

## Part A — API Strategy

### 1. Contract-first, REST, versioned

- **Style:** REST over HTTPS/JSON. Rationale in [ADR-0006](../adr/0006-api-contract.md).
  - *REST (chosen)* — ubiquitous, cache-friendly, trivial to consume from Swift/TS, matches Supabase/Edge Function grain, easiest to re-host on any backend.
  - *GraphQL* — great for flexible client queries and the dynamic-schema use case, but adds server complexity, caching difficulty, and a heavier client. Rejected for v1; the composed-schema endpoints already give us tailored payloads. Could be added later as an additive gateway if client query flexibility demands it.
  - *gRPC* — excellent typing/perf, poor fit for browser dashboard and Supabase Edge grain. Rejected.
- **Contract of record:** an **OpenAPI 3.1 spec** in `contract/openapi/v1/`. Client models (Swift DTOs, TS types) and server validation (zod) are **generated from / checked against** it. The spec is reviewed like schema.
- **Versioning:** URL-prefixed (`/v1/…`). Breaking changes → `/v2` with a deprecation window; additive changes stay in `/v1`. Clients send an app-version header so the backend can adapt/deprecate gracefully.

### 2. Conventions (uniform across all endpoints)

| Concern | Convention |
|---|---|
| **Resource naming** | plural nouns, kebab where needed: `/v1/listings`, `/v1/categories/{id}/schema` |
| **Pagination** | **cursor-based** (`?cursor=&limit=`) for feeds/search (stable under inserts); page-based only for admin tables |
| **Filtering/sorting** | `?filters=<encoded>&sort=<field>&order=`; filter grammar validated against category attribute definitions |
| **Partial/i18n** | `?locale=` resolves i18n server-side; `?fields=` optional sparse fieldsets for heavy resources |
| **Idempotency** | `Idempotency-Key` header on POSTs that create/charge (listings, payments) |
| **Caching** | `ETag` + `If-None-Match` on config/theme/category-schema; `Cache-Control` on static-ish reads |
| **Rate limiting** | per-token + per-IP; documented limits; `429` with `Retry-After` |
| **Correlation** | client sends `X-Request-Id`; echoed and logged end-to-end |

### 3. Standard envelopes

**Success** (single & collection):
```jsonc
// single
{ "data": { ... } }
// collection
{ "data": [ ... ], "page": { "nextCursor": "...", "hasMore": true } }
```

**Error** (one shape everywhere):
```jsonc
{
  "error": {
    "code": "validation_failed",         // stable machine code (enum)
    "message": "Human readable summary",  // localized by ?locale
    "requestId": "req_...",
    "fields": [                            // present for validation errors
      { "field": "mileage", "code": "max", "message": "Must be ≤ 2,000,000" }
    ]
  }
}
```

- **Stable `code` enum** drives client behavior; `message` is for display only.
- `fields[]` maps directly onto the **dynamic form** (field-level errors), closing the loop with the schema engine.
- HTTP status used correctly (400/401/403/404/409/422/429/5xx); the envelope adds the machine detail.

### 4. Client networking layer (iOS) — the abstraction that protects portability

```
UseCase → Repository → APIClient → APIEndpoint → (Supabase-backed transport)
```

- **`APIEndpoint`**: a value describing method, path, query, body, auth requirement, decoding type. One per contract operation, generated where possible.
- **`APIClient`**: protocol; the concrete implementation performs the request (currently via URLSession against Edge Functions, using the Supabase SDK **only** for auth token/session where convenient — isolated here).
- **Interceptors/middleware:** auth token injection, refresh-on-401, ret/backoff, logging, correlation id, error-envelope decoding → `DomainError`.
- **No Supabase type crosses `Networking`'s boundary.** Enforced by a CI grep + package graph. This is the literal mechanism for "replace Supabase later without touching Domain/Presentation."

### 5. Contract testing
- **Provider tests:** the backend is tested against the OpenAPI spec (request/response conformance) using `contract/examples` fixtures.
- **Consumer tests:** iOS/dashboard decode the same fixtures. A contract change that breaks a consumer fails CI.
- This shared-fixture approach keeps three platforms honest against one contract.

---

## Part B — Authentication Strategy

### 1. Foundation

- **Provider:** Supabase Auth (GoTrue), JWT-based — but **wrapped**. Clients authenticate through **our `/v1/auth` contract**, not the Supabase SDK's surface, so auth is swappable and consistent. Rationale in [ADR-0007](../adr/0007-authentication.md).
- **Methods (config-driven):** which providers are enabled is part of the Development Schema (`authentication providers`). Supported: email/password, OTP/phone (critical for Gulf classifieds), Sign in with Apple, Google, and anonymous/guest browsing.
- **Guest-first:** browsing/search/config/theme/schema are available to **anonymous** sessions (RLS allows public reads). Auth is required only to post, chat, favorite, or transact — matching classifieds UX.

### 2. Token handling (iOS)

- Access token (short-lived JWT) + refresh token. **Stored in Keychain**, never in SwiftData/UserDefaults.
- A `TokenStore` **actor** owns tokens; the networking interceptor injects the access token and performs **single-flight refresh** on 401 (concurrent requests await one refresh).
- Sign-out clears Keychain + caches; token revocation handled server-side.

### 3. Authorization

- **Roles/scopes** in the JWT claims: end-user vs. admin scopes; admin scopes further split (catalog_editor, moderator, finance, …) per [06 §5](06-dashboard-architecture.md#5-permissions--roles).
- **Enforced server-side** at two layers: Edge Function scope checks **and** RLS policies. The app never trusts client-side role checks for security (only for UX hiding).
- **Tenant claim** in the JWT scopes every query to the tenant ([ADR-0011](../adr/0011-multi-tenancy.md)).

### 4. Flows

```mermaid
sequenceDiagram
  participant App
  participant BFF as /v1/auth (Edge Fn)
  participant Auth as Supabase Auth
  App->>BFF: POST /v1/auth/otp/request {phone}
  BFF->>Auth: initiate OTP
  Auth-->>App: SMS code (out of band)
  App->>BFF: POST /v1/auth/otp/verify {phone, code}
  BFF->>Auth: verify → session
  BFF-->>App: { accessToken, refreshToken, profile }
  Note over App: tokens → Keychain; profile → cache
  App->>BFF: authorized requests (Bearer access)
  App->>BFF: POST /v1/auth/refresh (on 401, single-flight)
```

- **Sign in with Apple** required by App Store when other social logins exist — included by default when social auth is enabled.
- **Account linking** (phone + Apple + Google → one identity) handled server-side and exposed via `/v1/auth/link`.

### 5. Security posture (summary; full in [09 — Security](09-cross-cutting.md#security))
- TLS everywhere; certificate pinning optional per client config.
- No secrets in the app bundle; provider keys server-side only.
- Sensitive actions (payment, account deletion) may require re-auth/step-up.
- Rate limiting + bot protection on auth endpoints (OTP abuse is a real cost in SMS).
