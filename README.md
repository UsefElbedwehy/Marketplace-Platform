# White-Label Marketplace Platform

A production-ready **platform for manufacturing marketplace apps** — the marketplace equivalent of Shopify/Saleor/Medusa. One codebase (iOS + backend + admin dashboard), driven by backend **configuration**, becomes any branded, localized, multi-vertical classifieds marketplace **without source changes**.

Three engines carry the product:

- **Configuration & White-Label Engine** — what the app *is* (identity, branding, locales, currencies, features, providers).
- **Theme Engine** — how the app *looks* (semantic design tokens → live re-skin).
- **Dynamic Category & Attribute Engine** ⭐ — what the app *sells* (dashboard-defined categories, subcategories, and per-subcategory listing schemas; clients render forms & filters from backend metadata — schema-driven, never screen-driven).

## Status

📋 **Planning complete — awaiting approval before implementation.** No production code has been written yet.

## Start here

- **[📖 Master Implementation Plan](docs/planning/README.md)** — vision analysis, challenged assumptions, and the full architecture.
- **[🗺️ Implementation Roadmap](docs/planning/11-roadmap.md)** — dependency-ordered phases with exit criteria.
- **[🧩 Architecture Decision Records](docs/adr/README.md)** — every major decision with alternatives and trade-offs.
- **[🎯 Project Foundation (product brief)](PROMPTS/00_PROJECT_FOUNDATION.md)** — the source-of-truth intent.

## Tech stack (at a glance)

| Layer | Choice |
|---|---|
| iOS | SwiftUI · iOS 17+ · Clean Architecture + MVVM-C · Coordinators · Factory DI · SPM modules · SwiftData cache |
| Backend | Supabase (Postgres/Auth/Storage/Realtime/RLS) as data plane · **BFF via Edge Functions** exposing a versioned REST contract |
| Dashboard | Next.js (App Router) + TypeScript |
| Contract | OpenAPI 3.1 (contract-first), shared across all platforms |

See the [system architecture](docs/planning/01-system-architecture.md) for how these fit together.
