# Theme Engine

> Living document. Full design: [planning/07-configuration-whitelabel-theme.md §4](planning/07-configuration-whitelabel-theme.md#4-theme-engine).

Semantic design tokens (primitive → semantic → component layers) resolved at runtime; components read `theme.color.*`/`theme.font.*`, never literals — enforced by CI lint. See [ADR-0005](adr/0005-theme-engine.md).

**Status:** both halves are live. Backend/dashboard: `config.theme` stores versioned token documents, served via `GET /v1/theme` with ETag caching, published via `PATCH /v1/theme` from the dashboard's **Theme Studio** (verified: editing the `primary` token live-updates a preview card and persists). iOS: `ios/Packages/DesignSystem` resolves the same `ThemeDTO` into `Theme`/`SemanticColors`/`Typography`/`ThemeShape`, injects them via `ThemedRoot` (a color-scheme-reactive `\.semanticColors` environment value, so light/dark just works with no per-call-site branching), and exposes a first component slice reading only those tokens — verified live in the iOS Simulator in light and dark, with a passing `tooling/lint/boundaries.sh` check (no raw color/font literal outside `DesignSystem`, re-verified to actually fail on an injected violation). One cosmetic gap: iOS 26's new floating tab bar's selected-tab tint didn't pick up the theme color in manual testing — see `ios/Packages/DesignSystem/README.md`.
