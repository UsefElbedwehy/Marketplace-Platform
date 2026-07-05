# ADR-0015 — Swift Package Manager per-module modularization

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The foundation mandates SPM modularization and independent modules with no tight coupling ("keep modules independent", "avoid massive ViewModels/Coordinators"). We need boundaries that are enforced by the compiler, plus fast incremental builds and independent testability across ~20 feature modules.

## Decision
Every architectural unit is an **SPM target**: foundation packages (`Core`), capability packages (`Networking`, `Configuration`, `DesignSystem`, `DynamicForms`, `DomainKit`, `DataKit`), and one package per **Feature**. The dependency rules in [01 §4](../planning/01-system-architecture.md#4-module-boundaries--dependency-rules) are enforced by SPM (illegal import = compile error) plus a package-graph assertion test and CI import lints. Each feature package ships the foundation's module doc set (README/Architecture/Flow/API/Testing/Future). The **App target is the only composition root** (DI registration, white-label wiring).

## Alternatives considered
- **Single app target with folder grouping:** fastest to start, but boundaries are conventions only and rot; rejected — the whole point is enforced independence.
- **Xcode project + framework targets (no SPM):** heavier project files, worse for CI/codegen and cross-repo reuse; rejected in favor of SPM.
- **Micro-packages (a package per tiny type):** rejected — over-fragmentation; module granularity is per architectural unit/feature.

## Consequences
- (+) Compiler-enforced boundaries; parallel/incremental builds; per-module tests + docs.
- (+) Features can't import each other → true independence; cross-feature flow via DomainKit + coordinators.
- (−) More package manifests and initial wiring overhead. Accepted as the cost of enforced modularity.
