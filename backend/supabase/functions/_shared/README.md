# `_shared`

Shared Edge Function runtime: auth middleware, standard error envelope, zod validation derived from the contract, typed data-access helpers, and provider ports (payments/maps/push). Every function group in `../` imports from here so there's a single implementation of auth/errors/validation — no drift across endpoints. See [docs/planning/03-backend-architecture.md §2](../../../docs/planning/03-backend-architecture.md#2-edge-function-organization).

**Status:** Phase 0 stub — empty. Implemented starting Phase 1 (`auth.ts`, `errors.ts`) alongside the first real function groups (`v1-config`, `v1-theme`, `v1-auth`).
