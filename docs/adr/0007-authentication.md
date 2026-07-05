# ADR-0007 — Wrapped Supabase Auth behind `/v1/auth`

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
Auth must be consistent across clients, config-driven (which providers are enabled per client), support Gulf-classifieds norms (phone OTP, guest browsing), and remain swappable like the rest of the backend. App Store rules require Sign in with Apple when other social logins exist.

## Decision
Use **Supabase Auth (GoTrue, JWT)** as the identity provider but **wrap it behind our `/v1/auth` contract** — clients never bind to the Supabase auth SDK surface (the SDK may be used *only inside* the iOS networking layer for token/session mechanics). Support email/password, phone **OTP**, Sign in with Apple, Google, and **anonymous/guest** sessions, gated by the Development Schema. Access + refresh JWTs; iOS stores them in **Keychain** with an actor-owned `TokenStore` doing **single-flight refresh** on 401. Authorization via JWT scopes/roles + tenant claim, enforced by **both** Edge Function checks and RLS.

## Alternatives considered
- **Direct Supabase Auth SDK in clients:** simplest, but couples clients to Supabase and diverges per platform. Rejected — violates the portability mandate.
- **Third-party IdP (Auth0/Firebase/Clerk):** capable, but another vendor + cost and still needs wrapping. Deferred; the wrapper makes future adoption a backend change.
- **Custom auth:** rejected — security risk, reinventing GoTrue.

## Consequences
- (+) Consistent, swappable, config-driven auth; guest-first UX; store-compliant.
- (+) Dual enforcement (scopes + RLS) is defense-in-depth.
- (−) OTP/SMS is a cost + abuse vector → rate limiting + fraud checks required ([risk R12](../planning/10-risks.md)).
