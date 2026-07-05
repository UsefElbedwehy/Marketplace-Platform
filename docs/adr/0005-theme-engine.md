# ADR-0005 — Semantic-token Theme Engine, runtime-driven

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
Changing a client's theme must restyle the entire app with no code change, driven by config/dashboard, supporting the full semantic palette (primary/secondary/accent/background/surface/card/border/text/…/glass/material/badge/favorite/online/offline), light/dark, and RTL. "Never hardcode colors" is a hard rule.

## Decision
A three-layer token system: **primitives** (raw palette/scale) → **semantic tokens** (the vocabulary views use) → optional **component tokens**. iOS exposes a `Theme` through the SwiftUI `Environment`; components read `theme.color.primary`/`theme.font.…`, never literals. Tokens resolve per color-scheme and mirror for RTL. Themes come from seed `theme.json` **and** runtime overrides (`/v1/theme` / Theme Studio), merged, cached, hot-swappable. A **CI lint fails on raw color/font literals outside `DesignSystem`.**

## Alternatives considered
- **Asset-catalog named colors only:** native and simple, but not backend-driven, weak for the full semantic set + RTL logic, and not hot-swappable. Rejected as sole mechanism (still used for launch/app-icon assets).
- **Hardcoded palette per client build:** rejected — violates runtime re-skin and the no-hardcoding rule.

## Consequences
- (+) Whole-app restyle from data; testable via snapshot tests per theme × scheme × direction.
- (+) Enforced no-literals rule makes the guarantee real, not aspirational.
- (−) Indirection cost (token lookups) and a discipline requirement in reviews. Accepted.
