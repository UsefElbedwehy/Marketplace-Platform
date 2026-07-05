# White Label

> Living document. Full strategy: [planning/07-configuration-whitelabel-theme.md](planning/07-configuration-whitelabel-theme.md).

Build-time vs runtime split: identity/icons/entitlements/signing are build-time (`configs/clients/<c>/app.json` + assets → white-label pipeline); theme/locales/features/providers/flags are runtime (dashboard-editable, fetched at boot). See [ADR-0004](adr/0004-configuration-engine.md).

**Status:** the *runtime* side is fully live — `configs/clients/default` and `client_a` are seeded into `config.bundle`/`config.theme`, served via `GET /v1/config`/`/v1/theme`, and editable through the dashboard's **Config Studio** and **Theme Studio** (`PATCH`, RLS-gated to admins, verified to persist in a real browser session). The *build-time* half — the iOS white-label pipeline (`tooling/whitelabel`) and Fastlane lanes that turn `app.json` into a signed, branded binary — is blocked on iOS existing at all (Phase 3/4, deprioritized this session).
