# Dashboard

Next.js 16 (App Router) + TypeScript + Tailwind admin CMS — the control room and source of truth for marketplace structure. Consumes the **same REST contract** the apps do via `@marketplace-platform/contract-types` (never a private API) — see [docs/planning/06-dashboard-architecture.md](../docs/planning/06-dashboard-architecture.md) and [ADR-0010](../docs/adr/0010-dashboard-nextjs.md).

## Status

Implemented and verified live in a browser against real Postgres (via the backend gateway):

- **Schema Builder** (`/catalog`, `/catalog/[categoryId]`) ⭐ — category tree, attribute group/attribute/option creation, and a **live dynamic-form preview** (`components/DynamicFieldPreview.tsx`) that renders the same composed schema contract the app would. Verified: selecting a Brand correctly narrows the Model dropdown to just its dependent options.
- **Config Studio** (`/config`) — locale/currency/module/support editing, publishes via `PATCH /v1/config`. Verified: toggling a module and publishing persisted correctly (re-checked via a direct API query afterward).
- **Theme Studio** (`/theme`) — semantic color-token editing with a live-updating preview card, publishes via `PATCH /v1/theme`. Verified: changing the primary color re-skinned the preview instantly and persisted.
- **Listings** (`/listings`, `/listings/new`) — a real create-listing form (reusing the Schema Builder's `DynamicFormPreview` to actually submit, not just preview), "my listings" with role-appropriate actions (submit for review / withdraw / archive / mark sold), and a moderator/admin **moderation queue** (Approve/Reject). Verified: created a Phones listing, submitted it, confirmed self-approval is blocked (403), approved it as a moderator, confirmed it became publicly visible.
- **Users** (`/users`) — admin-only role management: lists tenant members (name/email/role/joined), a role dropdown per row, the caller's own row disabled with a tooltip. Verified: promoted a buyer to seller and back as admin (persisted via re-fetch), confirmed non-admins see a clean "only an admin" message, and confirmed via direct API calls that self-role-change and non-admin listing are rejected server-side too, not just hidden in the UI.

Not yet built: Advertisements/Analytics/Notifications screens (Phase 6/7 territory).

## Running locally

Requires the backend gateway running (no Docker needed — see [backend/README.md](../backend/README.md)):

```bash
cd backend && deno task serve     # :8000 — real Postgres-backed API
cd dashboard && npm run dev       # :3000 — this app
```

`.env.local` (gitignored; copy from `.env.example`) points the dashboard at the gateway via `NEXT_PUBLIC_API_BASE_URL`.

### Signing in

There is no real authentication yet (Phase 1's GoTrue-backed flows are unimplemented — see [ADR-0007](../docs/adr/0007-authentication.md)). The **DEV LOGIN** dropdown in the header (`components/DevIdentitySwitcher.tsx`) mints a local JWT via `POST /v1/dev-auth` for one of five fixed identities seeded by `backend/supabase/seed/02_dev_test_users.sql` (buyer/seller/catalog_editor/moderator/admin). `catalog_editor` or `admin` is required to write in the Schema Builder; `admin` for Config/Theme Studio publishes. **Remove this component when real auth lands.**

## Structure

```
src/
├── app/                    # routes: / (home), /catalog, /catalog/[categoryId], /listings, /listings/new, /config, /theme, /users
├── components/             # Nav, AuthProvider, DevIdentitySwitcher, CategoryTree, DynamicFieldPreview
└── lib/
    ├── api.ts              # typed fetch wrapper (auth header injection, ApiError)
    ├── session.ts           # dev-session localStorage (sub/role/tenantId/appRole)
    ├── contract-types.ts    # re-exports the OpenAPI-generated component schemas
    └── useApi.ts             # small fetch-on-mount + reload() hook
```

## Why a live preview renderer, not a static schema viewer

The Schema Builder's whole point is proving *"schema-driven, not screen-driven"* — the same generic form renderer must produce the Cars form and the Apartments form from different metadata alone. `DynamicFieldPreview.tsx` is a **web stand-in** for the iOS `DynamicForms` module (Phase 4, not yet built): it resolves `dependsOn` rules (`options_filtered_by`, `visible_when`) against the composed schema exactly as any real client would, client-side, from the already-inlined options (see `backend/src/catalog_service.ts` — v1 inlines small option sets rather than lazy-loading them). `/listings/new` reuses this exact component to actually create listings, which is the strongest proof available short of the iOS app itself: the same renderer, unmodified, drives both an admin preview and a real user-facing submission across categories with completely different schemas.

## A `useApi` gotcha worth knowing

The hook's effect originally closed over `[path, reloadKey, ...deps]` — a spread whose *length* varies by how many extra `deps` a given call site passes. React requires a hook's dependency array to have a stable length across renders for a given call site; once the Listings page started passing `[session?.sub]` (to force a refetch when the dev identity switches — the URL text `/v1/listings?owner=me` doesn't change even though the answer does), this occasionally produced a "final argument passed to useEffect changed size" console error under Fast Refresh. Fixed by collapsing the spread to a single `JSON.stringify(deps)` element, so the array is always exactly 3 items regardless of what's inside `deps`. If you add a new `useApi(path, deps)` call site, prefer passing a stable-shape `deps` array per call site, but the hook itself no longer requires that discipline.
