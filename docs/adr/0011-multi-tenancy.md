# ADR-0011 — Single-tenant-per-deployment, schema tenant-aware

**Status:** Accepted (pending approval) · **Date:** 2026-07-04

## Context
The product is sold to multiple customers. Data isolation, per-country data residency/regulation, and blast-radius containment matter. But we also want the option to run an efficient shared SaaS later. Choosing the tenancy model late forces a painful migration.

## Decision
Default to **single-tenant-per-deployment**: one Supabase project + one app build per client, giving strong isolation and per-region residency. **However, every domain table carries `tenant_id`** and RLS filters by a `tenant` JWT claim, so the *identical* schema can run as **shared multi-tenant** later with no structural migration — switching modes means enabling more tenant rows + tenant-scoped auth.

## Alternatives considered
- **Shared multi-tenant from day one (`tenant_id` + RLS, one deployment):** most cost-efficient at scale, but concentrates blast radius, complicates residency/regulatory isolation, and makes RLS bugs cross-customer incidents. Rejected as the *default*, kept as a supported future mode.
- **Schema-per-tenant in one database:** middle ground, but migration/ops complexity across many schemas. Rejected.
- **Ignore tenancy now, add later:** rejected — retrofitting `tenant_id` across a live schema is exactly the migration we refuse to risk.

## Consequences
- (+) Strong isolation + residency now; zero-migration path to shared SaaS later.
- (+) RLS reasoning is simpler (users within one tenant).
- (−) More deployments to operate per client (mitigated by automation/white-label pipeline).
- (−) Slight overhead carrying `tenant_id` in single-tenant mode. Accepted as cheap insurance.
