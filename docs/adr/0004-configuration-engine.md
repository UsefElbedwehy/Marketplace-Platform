# ADR-0004 — Configuration Engine + versioned Development Schema (build-time vs runtime split)

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
One codebase must become N branded marketplaces by configuration. Some knobs (theme, locales, features) can change at runtime; others (bundle id, app icon, entitlements, signing) are inherently build-time on iOS. Conflating them leads to broken promises ("change anything at runtime") or a confusing engine.

## Decision
Define a versioned **Development Schema** as the source of truth for an app's identity/branding/capabilities/providers, split into two explicit slices:
- **Build-time slice** (`configs/clients/<c>/app.json` + assets): identity, bundle id, icons, splash, URL schemes, entitlements, signing → drives the white-label build pipeline (codegen + Fastlane).
- **Runtime slice** (backend `config`, fetched at boot, cached): theme, locales, currencies, enabled features/modules, provider *selection*, links, flags → editable in the dashboard, live via config refresh.

Effective config = `default` deep-merged with `clients/<c>` overlaid with `env/<e>`. All configs are **validated against JSON Schema in CI** (invalid config fails the build). Backend is always the source of truth for the runtime slice; clients cache for offline.

**Implementation refinement (Phase 0):** the merge rule above applies to `config.json` and `theme.json` — both deep-merge, both validate as partial overlays (see [contract/README.md](../../contract/README.md#development-schema-merge-model)). `app.json` (build-time identity: bundle id, URL scheme, entitlements) does **not** merge — every client supplies a complete, independently-valid `app.json`. Rationale: build identity fields have no sensible "default" to inherit (a bundle id inherited by accident is a shipped-wrong-binary incident, not a convenience), so requiring explicitness here is safer than requiring it for branding/runtime fields where a shared default is exactly the point.

## Alternatives considered
- **Single runtime config for everything:** rejected — cannot change bundle id/icon/entitlements at runtime for an installed app; would over-promise.
- **Per-client code branches/forks:** rejected — destroys the platform thesis; config must be data.
- **Third-party remote-config service:** deferred — our backend already owns config; abstraction allows adopting one later.

## Consequences
- (+) Honest, testable boundary; adding a client = a `clients/<c>` folder + assets.
- (+) Config is a validated artifact, not a runtime surprise.
- (−) Two mechanisms (build pipeline + runtime fetch) to maintain. Accepted as inherent to native apps.
- No hardcoded currency/country/business constants anywhere ([foundation hard rule](../../PROMPTS/00_PROJECT_FOUNDATION.md)).
