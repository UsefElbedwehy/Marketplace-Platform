# White-Label Marketplace Platform — Master Implementation Plan

> **Status:** 📋 Planning — **awaiting approval**. No production code has been written.
> **Author:** Principal Architect session (Claude Code)
> **Date:** 2026-07-04
> **Source of truth for intent:** [`PROMPTS/00_PROJECT_FOUNDATION.md`](../../PROMPTS/00_PROJECT_FOUNDATION.md)

This directory is the **master implementation plan** for the platform. It is intentionally written so that a different senior engineer — or a future Claude Code session running a faster model — can implement the platform with minimal ambiguity by reading these documents in order.

---

## 1. Executive summary

We are not building a marketplace app. We are building a **product that manufactures marketplace apps** — the marketplace equivalent of Shopify/Saleor/Medusa. A single codebase (iOS + backend + admin dashboard), driven by backend configuration, must be able to become "Orange / Saudi / Cars", "Blue / Kuwait / Electronics", or "Green / Real Estate" **without source changes**.

Three engines carry the entire product. Everything else is a consumer of them:

| Engine | Owns | Why it is load-bearing |
|---|---|---|
| **Configuration & White-Label Engine** | App identity, branding, locales, currencies, feature flags, provider selection — the *Development Schema* | Turns one binary into N branded apps |
| **Theme Engine** | Semantic design tokens (colour/typography/spacing/elevation) | Turns branding config into a live, fully re-skinnable UI |
| **Dynamic Category & Attribute Engine** | Category tree, per-subcategory listing schemas, field types, validation, dependencies, localization | Turns one app into *any vertical* — cars, real estate, jobs, pets — with the dashboard as source of truth |

The **Dynamic Category & Attribute Engine is the highest-risk, highest-value component** and the primary subject of the v1 golden path. The listing experience is **schema-driven, never screen-driven**: clients render create-listing forms, filters, and detail views from backend metadata. If this engine is right, every future vertical is a data change. If it is wrong, we ship a cars app pretending to be a platform.

The backend boundary is a **BFF (Backend-for-Frontend) implemented as Supabase Edge Functions** exposing a **versioned REST contract we own**. Supabase (Postgres, Auth, Storage, Realtime, RLS) is the *data plane*; the app only ever speaks our contract. Supabase can later be replaced by NestJS/Go/Laravel without touching the app's Presentation, Domain, or Repository layers.

---

## 2. How to read this plan

Read in order. Each document is self-contained but assumes the ones before it.

| # | Document | What it decides |
|---|---|---|
| 00 | **This file** | Vision analysis, challenged assumptions, locked & open decisions |
| 01 | [System Architecture](01-system-architecture.md) | High-level architecture, repo structure, module boundaries, dependency graph |
| 02 | [iOS Architecture](02-ios-architecture.md) | Clean Architecture, MVVM-C, coordinators, Factory DI, SPM modules, SwiftData caching |
| 03 | [Backend Architecture](03-backend-architecture.md) | Supabase data plane + Edge Function BFF, business-logic placement, realtime, storage |
| 04 | [Database Architecture](04-database-architecture.md) | Core schema, config tables, tenancy, RLS, migrations |
| 05 | [Dynamic Category & Attribute Engine](05-dynamic-schema-engine.md) | ⭐ The flagship: schema modeling, metadata contract, dynamic forms, validation, dependencies |
| 06 | [Dashboard Architecture](06-dashboard-architecture.md) | Admin CMS (Next.js), schema builder, config studio |
| 07 | [Configuration, White-Label & Theme](07-configuration-whitelabel-theme.md) | Development Schema, white-label build pipeline, theme engine, feature flags |
| 08 | [API & Authentication Strategy](08-api-auth.md) | REST contract conventions, versioning, errors, pagination, auth flows, token handling |
| 09 | [Cross-Cutting Concerns](09-cross-cutting.md) | Testing, CI/CD, security, performance, scalability, observability, i18n/RTL, documentation |
| 10 | [Risk Assessment](10-risks.md) | Ranked risks, likelihood/impact, mitigations, kill-criteria |
| 11 | [Implementation Roadmap](11-roadmap.md) | Phased, dependency-ordered delivery plan with exit criteria |

**Architecture Decision Records** live in [`docs/adr/`](../adr/). Every major decision below links to an ADR that records the alternatives, trade-offs, decision, and consequences.

---

## 3. Vision analysis — what we are actually being asked to build

Decoding the foundation document into engineering reality:

1. **A product, not a project.** The unit of value is *"spin up marketplace #N"*, measured in hours of configuration, not weeks of code. This means the cost of the *second* marketplace must approach zero. Every "just hardcode it for now" is technical debt against the core value proposition.
2. **Configuration is the product surface.** Branding, locales, currencies, features, *and marketplace structure itself* (categories/attributes) are data owned by non-engineers via the dashboard. The app is a renderer.
3. **The backend is the brain.** Business rules live server-side so iOS/Android/Web/Desktop stay thin and consistent. Clients must not re-implement pricing, moderation, or validation logic.
4. **Portability is a hard constraint, not a nice-to-have.** "Never depend on Supabase directly" is repeated and central. The architecture must survive a backend swap.
5. **Longevity over speed.** Optimize for the codebase living and evolving for years, onboarding humans and AI agents. Documentation and clear module boundaries are features, not overhead.

---

## 4. Challenged assumptions & early architectural risks

A Principal Architect's job is to push back before code is written. The following are the assumptions I am explicitly flagging.

### 4.1 "Change configuration only, zero code changes" is aspirational — scope it honestly
**Reality:** Branding, theme, locales, feature flags, category/attribute schemas, and content are achievable as pure data. But **App Name, Bundle Identifier, App Icon, Splash, and native entitlements (push, sign-in-with-apple, deep-link domains)** are *build-time* artifacts on iOS — they cannot be changed at runtime for an already-installed app. **Mitigation:** split configuration into **build-time schema** (identity/signing/icons → drives Fastlane/codegen) and **runtime schema** (branding/theme/features/structure → fetched from backend and cached). We will be explicit about which knob lives where. See [ADR-0004](../adr/0004-configuration-engine.md).

### 4.2 The Dynamic Attribute Engine is where platforms go to die
**Risk:** A naïve Entity-Attribute-Value (EAV) model makes writes easy but queries (filter "cars, BMW, 2018–2022, <100k km, automatic") slow and painful, and can degrade into an unqueryable soup. **Mitigation:** a **hybrid model** — normalized *definitions* (categories/attributes/options as first-class tables the dashboard edits) + a **typed value store with generated columns / JSONB + expression indexes** for fast filtering, plus a search projection (Postgres FTS now, external search engine later). This is the single most important schema decision; see [`05`](05-dynamic-schema-engine.md) and [ADR-0003](../adr/0003-dynamic-attribute-engine.md).

### 4.3 Edge Functions as a full BFF has real limits
**Risk:** Deno Edge Functions are excellent for glue and business endpoints but are not a heavy application server — cold starts, execution limits, and awkwardness for large domains are real. **Mitigation:** keep the *contract* (OpenAPI) as the stable asset; implement it in Edge Functions now, but design so the contract can be re-hosted on NestJS/Go later with **zero client change**. Some read paths may go straight through PostgREST *but only ever behind our APIEndpoint abstraction and never with Supabase types leaking to the app*. See [ADR-0002](../adr/0002-backend-bff-edge-functions.md).

### 4.4 White-label multiplies the test matrix combinatorially
**Risk:** N clients × M feature-flag combinations × K locales (incl. RTL) is untestable by brute force. **Mitigation:** treat the **default reference config** as the canonical CI target, snapshot-test the theme/schema renderers against a small set of *representative* configs, and make configs themselves **validated artifacts** (schema-checked in CI) rather than free-form.

### 4.5 RTL + Arabic is a day-one constraint, not a later locale
The target markets (Saudi, Kuwait, general Gulf classifieds) are Arabic-first. Retrofitting RTL, bidirectional text, locale-aware number/date/currency formatting, and mirrored iconography is expensive. **Decision:** i18n + RTL are foundational requirements in the design system from the first component. See [`09`](09-cross-cutting.md#i18n).

### 4.6 Multi-tenancy model must be chosen before the schema is written
Selling to multiple customers can mean *one deployment per customer* (isolation, simpler) or *one shared multi-tenant deployment* (efficiency, complex RLS). Choosing late forces a painful migration. **Decision:** default to **single-tenant-per-deployment** (one Supabase project + one app per client) for data isolation and regulatory simplicity, while designing the schema to be **tenant-aware** so a shared-tenant SaaS mode is possible later without a rewrite. See [ADR-0011](../adr/0011-multi-tenancy.md).

### 4.7 "Business logic in the backend" vs. responsive UX is a tension
Fully server-authoritative validation is correct but round-trips hurt form UX. **Mitigation:** the backend owns *authoritative* validation and ships **machine-readable validation rules** as part of attribute metadata, so clients can render *optimistic, local* validation from the *same* rules — one source of truth, two enforcement points.

---

## 5. Decisions locked this session

These are settled (by the foundation doc and your answers) and drive everything downstream:

| Decision | Choice | Reference |
|---|---|---|
| iOS architecture | Clean Architecture + MVVM-C + Coordinators + Factory DI + SPM modularization + SwiftData cache | [ADR-0001](../adr/0001-clean-architecture-ios.md) |
| Backend boundary | BFF via Supabase Edge Functions, versioned REST contract we own | [ADR-0002](../adr/0002-backend-bff-edge-functions.md) |
| Marketplace model | General classified marketplace, multi-vertical, schema-driven | [ADR-0003](../adr/0003-dynamic-attribute-engine.md) |
| Listing structure | Dashboard-controlled Dynamic Category & Attribute Engine (source of truth) | [`05`](05-dynamic-schema-engine.md) |
| Config model | Development Schema (versioned), split build-time vs runtime | [ADR-0004](../adr/0004-configuration-engine.md) |
| Data plane | Supabase (Postgres/Auth/Storage/Realtime/RLS) | [ADR-0002](../adr/0002-backend-bff-edge-functions.md) |
| Dashboard | Next.js (App Router) + TypeScript | [ADR-0010](../adr/0010-dashboard-nextjs.md) |
| Repo layout | Monorepo, path-scoped | [ADR-0009](../adr/0009-monorepo.md) |
| Tenancy | Single-tenant-per-deployment, schema tenant-aware | [ADR-0011](../adr/0011-multi-tenancy.md) |

## 6. Open decisions requiring your ratification (product-level)

These are safe to defer past planning but must be answered before the relevant phase. Sensible defaults are proposed; none blocks starting the foundation.

1. **Payments provider(s) & regions** — abstraction is designed now; concrete provider (e.g. Stripe vs. HyperPay/Tap/MyFatoorah for Gulf) chosen at Payments phase.
2. **Maps provider** — Apple Maps (free, native) as default vs. Google/Mapbox (features, cross-platform parity).
3. **Push & realtime chat scale** — Supabase Realtime for v1; evaluate dedicated infra if chat volume grows.
4. **Search backend** — Postgres FTS for v1; Meilisearch/Typesense/OpenSearch when filter complexity or scale demands.
5. **Moderation policy** — manual dashboard review for v1; ML-assisted later.

---

## 7. The approval gate

Per the foundation document's staged-development mandate, **implementation does not begin until you approve this plan.** When you approve, Phase 0 ([Roadmap](11-roadmap.md#phase-0)) begins: repository scaffolding, the Development Schema format, the default reference config, and CI — the foundation every other phase stands on.
