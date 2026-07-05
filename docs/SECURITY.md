# Security

> Living document. Full posture: [planning/09-cross-cutting.md — Security](planning/09-cross-cutting.md#security).

TLS everywhere, dual-enforced authz (Edge Function scopes + RLS), tenant isolation via `tenant_id` + RLS, no secrets in the app bundle or repo, signed-URL media access, immutable audit log for admin/schema/config mutations. See [ADR-0002](adr/0002-backend-bff-edge-functions.md), [ADR-0007](adr/0007-authentication.md), [ADR-0011](adr/0011-multi-tenancy.md).

**Status:** Phase 0 — no runtime yet. A dedicated threat model is produced in Phase 8 hardening, but security-relevant boundaries (RLS, scopes, secret handling) are enforced from Phase 1 onward.
