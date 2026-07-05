# 10 — Risk Assessment

Ranked by **exposure = likelihood × impact**. Each risk has a mitigation and, where relevant, an early **signal** to watch and a **fallback**. R1–R3 are existential to the platform thesis; the rest are serious but bounded.

| # | Risk | Likelihood | Impact | Exposure |
|---|---|---|---|---|
| R1 | Dynamic attribute engine can't filter fast/flexibly at scale | Med | Critical | 🔴 High |
| R2 | White-label "zero code change" over-promised → per-client forks | Med | Critical | 🔴 High |
| R3 | Edge Functions inadequate as full BFF | Med | High | 🔴 High |
| R4 | Cross-platform metadata/renderer drift | Med | High | 🟠 Med-High |
| R5 | Test matrix explosion (clients × flags × locales) | High | Med | 🟠 Med-High |
| R6 | Supabase lock-in despite abstraction | Low-Med | High | 🟠 Med |
| R7 | RTL/Arabic correctness debt | Med | Med | 🟠 Med |
| R8 | Schema mis-edits break live marketplaces | Med | High | 🟠 Med |
| R9 | Scope/gold-plating → never ships | High | Med | 🟠 Med |
| R10 | Multi-tenancy decision reversed late | Low | High | 🟡 Low-Med |
| R11 | Payment/provider regional complexity (Gulf) | Med | Med | 🟡 Low-Med |
| R12 | Cost blow-up (SMS OTP, storage/CDN, functions) | Med | Med | 🟡 Low-Med |

---

### R1 — Dynamic attribute engine performance/flexibility
**Why critical:** it's the product thesis; if filtering "BMW, 2018–2022, <100k km, automatic" is slow or awkward, the platform fails at its main job.
**Mitigation:** hybrid model (typed value store + JSONB projection + generated columns + GIN), search-engine escape hatch behind the `/v1/listings` contract ([05](05-dynamic-schema-engine.md), [ADR-0003](../adr/0003-dynamic-attribute-engine.md)).
**Early signal:** benchmark the seed catalog with realistic volumes (100k+ listings) in Phase 2; p95 filter latency budget.
**Fallback:** promote hot attributes to generated columns aggressively; adopt Meilisearch/Typesense earlier than planned — no client change required.

### R2 — White-label over-promise
**Why critical:** the whole value prop is "config, not code." If clients need code forks, we've built a bespoke shop.
**Mitigation:** honest [build-time vs runtime split](07-configuration-whitelabel-theme.md#11-build-time-vs-runtime-split-a-deliberate-honest-boundary); validated config artifacts; the *second* client must be config-only by design; treat any "just fork it" as a defect with a config-engine gap ticket.
**Early signal:** stand up `client_a` **and** `client_b` from config early (Phase 5) — if either needs code, fix the engine, not the client.
**Fallback:** a documented, minimal **extension-point** mechanism (config-declared custom modules) so genuine one-offs don't corrupt the core.

### R3 — Edge Functions as full BFF
**Mitigation:** contract is the stable asset; functions stay small; heavy reads via views; design for re-host on NestJS/Go without client change ([ADR-0002](../adr/0002-backend-bff-edge-functions.md)).
**Early signal:** cold-start p95, function timeouts, or awkward large-domain code in Phase 2–3.
**Fallback:** move the hot/heavy contexts to a standalone service tier; keep light contexts on Edge Functions. Contract conformance suite validates the move.

### R4 — Cross-platform renderer drift
**Mitigation:** one contract, shared `contract/examples` fixtures, cross-platform renderer conformance tests (dashboard preview must equal app render).
**Signal:** any place a client special-cases a field type not in the contract.
**Fallback:** tighten the metadata spec; add missing field types to the contract, never to one client only.

### R5 — Test matrix explosion
**Mitigation:** canonical `default` config is the CI target; snapshot only a curated representative set; configs are validated artifacts so most "config bugs" are caught statically, not by running N apps ([09 — Testing](09-cross-cutting.md#testing-strategy)).
**Fallback:** property-based config generation for the validator; keep runtime feature combinations orthogonal (flags independent).

### R6 — Supabase lock-in
**Mitigation:** the entire architecture is built around this fear — wrapped auth/storage/realtime, contract-of-record, no Supabase types past `Networking`, conformance suite. Lock-in is *structurally* resisted.
**Signal:** any leak of Supabase-specific shapes into the contract or client.
**Fallback:** the documented re-host path; because the contract is stable, this is a backend project, not a rewrite.

### R7 — RTL/Arabic debt
**Mitigation:** RTL/i18n from component one; RTL snapshot tests; backend content is i18n JSON with fallback; dashboard requires all locales before publish.
**Signal:** any hardcoded string or LTR-only layout in review.

### R8 — Schema mis-edits break live marketplaces
**Mitigation:** stage→preview→publish with version bump; soft-disable over delete; guarded type changes; full audit; live preview uses the real renderer ([06 §3](06-dashboard-architecture.md#3-the-schema-builder-most-important-screen)).
**Fallback:** schema version rollback (revert to previous published version).

### R9 — Scope / gold-plating
**Mitigation:** roadmap is dependency-ordered with **thin vertical slices** and explicit exit criteria; the golden path (post + search across 3 verticals) is the forcing function; defer non-essential modules behind flags.
**Signal:** a phase running long without a demoable slice.

### R10 — Multi-tenancy reversal
**Mitigation:** schema is tenant-aware from day one even in single-tenant mode ([ADR-0011](../adr/0011-multi-tenancy.md)), so switching modes needs no structural migration.

### R11 — Gulf payment complexity
**Mitigation:** payment provider **port**; concrete provider (Tap/HyperPay/MyFatoorah/Stripe) chosen at Payments phase, not baked into core; regional methods (mada, KNET, Apple Pay) modeled behind the port.

### R12 — Cost blow-up
**Mitigation:** OTP rate limiting + fraud checks (SMS is the sneaky cost); image downsizing + CDN; small warm functions; cost dashboards/alerts; per-deployment budgets.

---

## Kill / re-evaluation criteria
- If, after Phase 2, the hybrid attribute model cannot hit filter-latency budgets even with generated columns **and** a search engine → escalate the data model (consider a document/search-first store for listings) before building more features.
- If, at `client_b`, config-only setup is impossible → **stop feature work** and close the config-engine gap; the platform thesis is at stake.
- If Edge Functions block a core context in Phase 3 → carve that context onto a standalone service early rather than fighting the runtime.
