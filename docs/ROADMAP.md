# Roadmap

> **Living document** — tracks actual phase status. The dependency-ordered plan with exit criteria lives in [planning/11-roadmap.md](planning/11-roadmap.md); this file tracks *where we actually are*.

## Status

| Phase | Status | Notes |
|---|---|---|
| P0 — Foundation & scaffolding | 🟢 Done | Repo layout, contract bootstrap, default config + client_a stub, config-validation + contract-types packages, CI + boundary lints, local Supabase harness. |
| P1 — Backend core (DB, auth, config/theme contract) | 🟢 Done | `platform`/`identity`/`config` schemas, RLS, wrapped-auth groundwork (custom access token hook), `/v1/config` + `/v1/theme` (GET+PATCH) — all verified against real local Postgres. Real GoTrue-backed auth flows (email/OTP/Apple/Google) remain unimplemented — see caveat below. |
| P2 — Dynamic Category & Attribute Engine (backend) ⭐ | 🟢 Done | `catalog` + `listing` schemas (hybrid attribute value store per ADR-0003), full golden-path seed (11 categories, Cars/Apartments/Phones fully modeled + 8 lighter verticals), `/v1/categories/*`, `/v1/attributes/*`, `/v1/listings` (read+write) — verified end-to-end against real Postgres, including the dependent-options pattern (Model filtered by Brand). |
| P3 — iOS foundation | 🟢 Done | SPM workspace (`Core`, `DomainKit`, `Networking`, `Configuration`, `DesignSystem`, `DataKit`, `App`), Factory DI, boot sequence (concurrent config+theme fetch), dev-auth sign-in flow, `AppCoordinator`/`TabCoordinator` + themed tab shell — verified live in the iOS Simulator (boot → auth → main → sign-out) in light, dark, and RTL (Arabic). See below. |
| P4 — iOS golden path (DynamicForms + Listings) ⭐ | 🟢 Done | `DynamicForms`, `Features/Listings`, `Features/Search` built and wired into the app; created a Car/Apartment/Phone through identical code, walked one through real moderation to published, confirmed Search's dynamic filter surfaced it, confirmed a server-side schema edit reflects after refresh with no rebuild; DynamicForms snapshot tests across two structurally different verticals × LTR/RTL × light/dark all pass. See below. |
| P5 — Dashboard + white-label proof ⭐ | 🟡 In progress | **Schema Builder, Config Studio, Theme Studio, Listings/Create-listing, and a Users (admin role management) page are built and verified live in a browser** against real Postgres (category/attribute CRUD, config publish, theme publish + live re-skin preview, listing creation via the schema-driven form, moderation approve/reject, admin role changes). The iOS white-label *build pipeline* (Fastlane, codegen) is out of scope until P3/P4 land. |
| P6 — Social & engagement | ⬜ Not started | |
| P7 — Commerce, monetization & trust | 🟡 In progress | **Moderation** (approve/reject queue, status state machine) is done — see below. Subscriptions/payments/wallet/advertisements untouched. |
| P8 — Hardening, scale & next platforms | ⬜ Not started | |

Legend: ⬜ not started · 🟡 in progress · 🟢 done · ⭐ thesis-critical (platform-proving) phase.

## Session note: reprioritization

The user redirected this session away from the roadmap's original P0→P3 ordering (which ran iOS foundation in parallel with the schema engine) to instead push the **configuration engine, category/attribute engine, listing engine, and dashboard** first — the parts that constitute the platform's core business value — ahead of iOS and further dev tooling. What shipped first: essentially all of P1 and P2, plus the dashboard portion of P5. iOS (P3) was picked back up in a later "continue" and is now done too — see below.

## Phase 0 exit criteria — verified

Per [planning/11-roadmap.md#phase-0](planning/11-roadmap.md#phase-0--foundation--scaffolding):
- ✅ `npm run validate:config` — 21/21 checks pass.
- ✅ `npm run lint:boundaries` — verified to actually **fail** on injected violations before being verified clean.
- ✅ `npm run generate:types` + `npm run typecheck:contract-types` — contract types compile under `tsc --strict`.
- ⚠️ Local Supabase stack (`supabase start`, the Docker-based CLI) — still not run; superseded in practice by the local-Postgres approach below.

## Phase 1 + 2 — how they were verified without Docker

No Docker is available in this environment. Rather than block on it, this session:
1. Installed **PostgreSQL and Deno directly via Homebrew** (both reversible, standard CLI dev tools) to get a *real* database and a *real* Deno runtime.
2. Wrote all migrations/RLS/triggers as real SQL, applied via `backend/scripts/local-db-reset.sh`, and built a from-scratch test harness (`backend/tests/sql/`, run via `backend/scripts/run-rls-tests.sh`) that exercises 27 real assertions — role-switching, simulated JWT claims, privilege-escalation attempts, cross-tenant isolation, type-enforcement triggers — all against the genuine Postgres RLS engine.
3. Wrote the Edge Functions as real Deno/TypeScript (`backend/supabase/functions/`), with `_shared/db.ts` reproducing PostgREST's per-request `SET ROLE` / `SET request.jwt.claims` behavior itself, so RLS applies exactly as it would in production. A `POST /v1/dev-auth` endpoint (explicitly excluded from the OpenAPI contract) mints locally-signed JWTs in place of GoTrue.
4. Ran everything end-to-end — `backend/scripts/serve-local.ts` combines every function behind one local HTTP server — and drove the actual dashboard UI against it in a real browser (Preview tool), verifying category/attribute creation, dependent-option filtering, config publish, and theme publish with live re-skin, with persistence confirmed via direct Postgres queries after each write.

**What's genuinely unverified:** the production Supabase Edge Runtime (Docker-based `supabase functions serve`) itself, and real GoTrue-issued JWTs — both require Docker/a hosted Supabase project. The code is written to the same interfaces either way (see `backend/supabase/functions/_shared/db.ts`'s header), so this is a deployment-verification gap, not a design gap. See [backend/README.md](../backend/README.md#local-development) and [backend/supabase/functions/README.md](../backend/supabase/functions/README.md).

## Listings management + moderation (a Phase 6/7 slice)

Extends P2/P5 rather than a clean new phase: `PATCH /v1/listings/{id}` with a status state machine (`draft → pending_review → published/rejected`, etc.), a dashboard Listings page (seller "my listings" + moderator queue), and — notably — a real **Create Listing** page (`/listings/new`) that reuses the Schema Builder's dynamic-form renderer to submit an actual listing, not just preview one. Verified live: created an iPhone 15 listing, submitted for review, confirmed self-approval is blocked (403), approved it as a moderator, confirmed public visibility. See [CHANGELOG.md](../CHANGELOG.md) for the two real bugs this caught (a gateway routing gap, and a React hook dependency-array-length bug).

## Admin user/role management (a Phase 5 slice)

Building the dashboard's Users screen (listed among CMS-managed resources in [planning/06-dashboard-architecture.md](planning/06-dashboard-architecture.md)) surfaced a real gap: the original self-escalation trigger blocked **all** non-service_role `app_role` changes, so not even an admin could promote another user through the app. Fixed with a forward-only migration (`20260704155058_identity_admin_role_management.sql`) adding a `profile_update_admin` RLS policy and narrowing the trigger to: always block self-modification of `app_role`/`tenant_id`, allow admin/super_admin to change **another** user's `app_role`, keep `tenant_id` service_role-only always. `GET /v1/users` + `PATCH /v1/users/{id}` (admin-only), `backend/src/user_service.ts` (6 unit tests), 7 new RLS assertions (41 total), and a dashboard `/users` page — verified live: promoted a buyer to seller as admin (persisted), confirmed an admin cannot change their own role (403, server-enforced independent of the UI's disabled control), confirmed a non-admin gets 403 listing users.

A second, unrelated bug surfaced while writing the new RLS assertions: `test.act_as_service()` reset the Postgres role but left the previous `test.act_as()` call's `request.jwt.claims` in place, so `auth.role()` (which reads that GUC, not the actual role) still reported `'authenticated'` — a test-harness gap, not an app bug, since the real request path always sets role and claims together atomically. Fixed by having `act_as_service()` also set the claims blob.

## Phase 3 — iOS foundation ⭐

Six SPM packages (`Core`, `DomainKit`, `Networking`, `Configuration`, `DesignSystem`, `DataKit`) plus the `App` composition root, built bottom-up with real `swift test` runs at every step (40 tests across the five non-UI packages, plus `DesignSystem`'s 9 logic tests + 3 real `xcodebuild`-run snapshot tests). Full breakdown per package in each `ios/Packages/*/README.md`.

**How the App target actually gets built:** a bare SPM `.iOSApplication` product (`import AppleProductTypes`) builds via `xcodebuild build` but doesn't get wrapped into an installable `.app` by the CLI alone (verified — it only produces a raw Mach-O). [Tuist](https://tuist.dev) (already installed in this environment) generates a real `.xcodeproj`/`.xcworkspace` from `ios/Tuist.swift` + `ios/Tuist/Package.swift` + `ios/Project.swift` that *does* produce a proper `.app`, installable and screenshot-able via `xcrun simctl`. The packages themselves stay plain SPM — Tuist only wraps the App target. See `ios/App/README.md`.

**Verified live in the iOS Simulator**, against the real local backend gateway, no mocks:
- App boots, fetches config **and** theme concurrently (`async let` in `AppCoordinator.start()`), and renders the themed dev sign-in screen.
- Tapping a dev identity performs a real `POST /v1/dev-auth` round trip, persists the session to the Keychain, and transitions to the themed tab shell (Home/Search/Sell/Chat/Profile placeholders).
- Profile tab reads the session back out of the Keychain and displays it; Sign out clears it and returns to the auth screen.
- All of the above is asserted by real `XCUITest`s (`ios/App/UITests/BootAndAuthUITests.swift`), not just a screenshot — there's no `xcrun simctl` tap primitive, so UI tests are how anything past a static screenshot gets verified here.
- **Dark mode**: `xcrun simctl ui <device> appearance dark` — background/card/border/text all correctly resolve to `theme.json`'s dark palette.
- **RTL**: a second UI test (`RTLLocaleUITests`) launches with `-AppleLanguages (ar) -AppleLocale ar_SA`, asserts the Arabic translations render, and screenshots confirm the layout actually mirrors (card text flips from leading- to trailing-aligned), not just that strings translated.
- DI graph resolves end-to-end with zero missing Factory registrations (the whole boot→auth→profile→sign-out chain exercises `Core`, `DomainKit`, `Networking`, `Configuration`, `DesignSystem`, and `DataKit` registrations together).

**Known cosmetic finding, not chased further:** iOS 26's new floating "Liquid Glass" tab bar didn't pick up `.tint()` for the selected tab's glyph color in manual testing, even though the identical color renders correctly everywhere else (buttons, cards — confirmed via snapshot tests). A static `UITabBar.appearance()` override would fix it but conflicts with the live theme-hot-swap guarantee (ADR-0005), so it's left as a known finding for a future iOS SDK revision rather than worked around.

## Phase 4 — iOS golden path: DynamicForms + Listings ⭐

The point of the whole exercise: prove the app is *schema-driven, not screen-driven* by posting a Car, an Apartment, and a Phone through the exact same code. Three new SPM packages (`DynamicForms`, `Features/Listings`, `Features/Search`) plus extensions to the Phase 3 foundation packages — full breakdown per package in each `ios/Packages/*/README.md`; the two-part DI pattern (registration-point declarations in `DomainKit`, concrete overrides in `App`) is explained in [IOS_ARCHITECTURE.md](IOS_ARCHITECTURE.md).

**Verified live in the iOS Simulator**, against the real local backend gateway and a real Postgres, via `XCUITest` (`ios/App/UITests/GoldenPathUITests.swift`, `SchemaLiveEditUITests.swift`):
- Created a **Car** (BMW X5 — option fields plus a Brand→Model `options_filtered_by` dependency), an **Apartment** (bedrooms/bathrooms/area — a schema with no option fields or dependencies at all, the structural opposite of Cars/Phones), and a **Phone** (Apple iPhone 15 — the same dependent-options pattern, a different vertical) — all three through the identical `CreateListingView`/`DynamicFormView` code path, zero vertical-specific screen code.
- Walked the Car listing through the **real moderation pipeline** (submit for review as the seller → sign in as a moderator → approve) and confirmed **Search's dynamic filter** (`brand = BMW`) surfaced it — proving browse+filter against a genuinely published listing end-to-end, not a stubbed one. (A freshly created listing lands in `draft` and RLS hides anything non-`published` from a public search; there is no self-serve publish, so this required actually driving the moderation queue rather than searching a listing right after creating it.)
- Separately verified **"edit a schema server-side → app reflects it after refresh, no rebuild"**: added a new attribute to the Phones category through the real `catalog_editor`-gated write API (the same path the dashboard's Schema Builder uses) while the app was already running and the create-listing form for Phones was already open, then confirmed the new field appeared after re-selecting the same category — no relaunch, no rebuild.

**Two real bugs the golden-path UI test caught and fixed at the source** (see [CHANGELOG.md](../CHANGELOG.md) for the full write-up): an accessibility-collapsing bug in `MyListingsView` that made every owner/moderator action button unreachable to VoiceOver (and to the test), and a `@State`-initial-value race in `SellTabView`/`MyListingsViewModel` that meant a moderator could never actually see the moderation queue, no matter how they signed in.

**DynamicForms snapshot tests** (the roadmap's third exit criterion) are done: a curated matrix across two structurally different fixtures (Cars-shaped — dropdowns + a Brand→Model dependency; Apartments-shaped — pure number/bool fields, no options at all) × representative {LTR/RTL} × {light/dark} slices, 5 tests total, run via `xcodebuild test -scheme DynamicForms` against a real iOS Simulator. See `ios/Packages/DynamicForms/README.md`.

**Phase 4 is done.**

See [CHANGELOG.md](../CHANGELOG.md) for a chronological log of what shipped.
