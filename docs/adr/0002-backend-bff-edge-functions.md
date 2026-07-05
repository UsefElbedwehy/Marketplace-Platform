# ADR-0002 — Backend boundary = BFF via Supabase Edge Functions

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The foundation mandates that clients never depend on Supabase directly and that business logic live in the backend, while starting on Supabase and preserving the option to replace it (NestJS/Laravel/Go/Spring) without touching client Domain/Presentation/Repository layers. We need a boundary that is portable yet fast to build.

## Decision
Use Supabase as the **data plane** (Postgres, Auth, Storage, Realtime, RLS) and implement a **Backend-for-Frontend (BFF) as Supabase Edge Functions** that exposes a **versioned REST contract we own** (OpenAPI, `/v1`). Clients speak only that contract. The contract — not Supabase — is the asset clients depend on.

## Alternatives considered
- **Direct Supabase SDK / PostgREST as the app API:** fastest, least code. Rejected as the *public* contract — it leaks table shapes and Supabase specifics, violating the portability mandate and pushing business logic into the DB/client. (We still use PostgREST internally, never client-facing.)
- **Standalone API service (NestJS/Go) in front of Supabase now:** most portable, most testable. Rejected for v1 — highest upfront engineering + ops cost; premature before product-market fit. Kept as the documented *scale/portability escape hatch*.

## Consequences
- (+) Business logic server-side; Supabase swappable; clients insulated by the contract.
- (+) Faster than a full standalone service; leverages Supabase Auth/Storage/Realtime/RLS.
- (−) Edge Functions (Deno) have cold-start/execution limits and are awkward for very large domains ([risk R3](../planning/10-risks.md)). Mitigation: keep functions small, heavy reads via views, and design so the contract can be re-hosted on NestJS/Go with **zero client change**, validated by a contract-conformance suite.
- Supabase-specific features (RLS, Realtime, Storage) are wrapped behind our own semantics, never leaked to clients.
