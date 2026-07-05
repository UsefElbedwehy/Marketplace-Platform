# ADR-0001 — Clean Architecture + MVVM-C on iOS

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The iOS app is one of several clients of a long-lived platform. It must (a) keep business rules out of the UI, (b) be independent of Supabase, (c) be unit-testable without UI or network, and (d) support ~20 independent feature modules without "massive ViewModels/Coordinators." The foundation mandates Clean Architecture + MVVM-C + Coordinator + SOLID.

## Decision
Adopt **Clean Architecture** with four layers (Presentation → Domain ← Data → Infrastructure), the **dependency rule** pointing inward, and **MVVM-C** in Presentation: dumb SwiftUI Views, `@Observable @MainActor` ViewModels that call use cases and emit navigation *intents*, and **Coordinators** (one per feature flow) owning navigation.

## Alternatives considered
- **Vanilla SwiftUI "MV"** (`@Observable` models → services): least boilerplate, fastest start. Rejected — business logic leaks into views, Supabase-independence and multi-client reuse become impractical, tests need the UI.
- **TCA (The Composable Architecture):** excellent testability/consistency. Rejected for v1 — steep learning curve, heavy conceptual buy-in, and it constrains hiring/onboarding; MVVM-C meets the goals with a lower floor.
- **VIPER:** maximal separation. Rejected — ceremony-heavy, dated for SwiftUI.

## Consequences
- (+) Pure, portable domain; use cases testable in isolation; Supabase-independence is structural.
- (+) Feature modules stay independent; navigation isolated in coordinators.
- (−) More layers/boilerplate and mapping (DTO↔Entity). Accepted as the cost of longevity.
- Enforced by SPM boundaries ([ADR-0015](0015-ios-modularization.md)) and CI import lints.
