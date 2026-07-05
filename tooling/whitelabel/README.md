# White-label pipeline

`whitelabel build --client <c> --env <e>` — validates the client's config, generates build-time artifacts (Info.plist, entitlements, asset catalogs, xcconfig) from `configs/clients/<c>/app.json`, installs branding assets, and invokes the matching Fastlane lane. See [docs/planning/07-configuration-whitelabel-theme.md §3](../../docs/planning/07-configuration-whitelabel-theme.md#3-white-label-pipeline-build-time).

**Status:** Phase 0 stub — empty (config validation already exists today via `packages/config-validation`). The build/codegen pipeline itself is implemented in Phase 5.
