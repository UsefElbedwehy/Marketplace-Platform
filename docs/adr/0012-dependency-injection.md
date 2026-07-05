# ADR-0012 — Factory for iOS dependency injection

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
~20 feature modules depend on abstractions (repositories, providers) whose concrete implementations are chosen at the composition root — this is where "swap Supabase for X" is realized. We need testable, compile-safe DI that fits SPM modularization and SwiftUI previews.

## Decision
Use **Factory** (hmlongco) as the DI container. Feature modules declare *protocol* dependencies; the **App target (composition root)** registers concrete implementations. Tests and previews override registrations per case. Constructor injection remains the default within modules; the container wires the graph at the root.

## Alternatives considered
- **Manual constructor injection only:** purest, zero deps, but hand-wiring the full graph across ~20 modules at the root becomes unwieldy and error-prone.
- **swift-dependencies (Point-Free):** excellent, but pulls toward its ecosystem/TCA conventions and adds conceptual weight not needed with MVVM-C.
- **Resolver / Swinject:** viable; Factory chosen for being lighter, compile-time-friendlier, and preview/test-ergonomic.

## Consequences
- (+) Lightweight, unopinionated, testable; clean composition-root swap point.
- (+) A DI graph-resolution test catches missing registrations in CI.
- (−) A third-party dependency in Core — mitigated by isolating DI behind a thin `Core` facade so it, too, is swappable.

## Addendum (Phase 4): where the `Container` extension itself lives

The decision above says the App target *registers* concrete implementations, but doesn't say where the `Container` extension *declaration* (the computed `Factory<Protocol>` property Feature packages resolve against) lives — and a Feature package can't see a declaration made in `App`, since Features never depend on the App target. Phase 4 settled this: the declaration lives in `DomainKit` (the lowest layer visible from every Feature), with a `fatalError` placeholder body; `App`'s composition root supplies the real implementation via `container.someProperty.register { ConcreteImpl(...) }`. This works because a `FactoryKey`'s identity is the accessor's return type + property name, not its file/line, so a declaration in one module and an override from another target the same registration. `Core` itself keeps the one exception (`appLogger`) that has a real default and never needs an App-specific override.
