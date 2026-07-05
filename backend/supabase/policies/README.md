# RLS Policies

Row-Level Security policies as reviewed SQL, applied via migrations (this directory holds them as readable, reviewable source; the actual `CREATE POLICY` statements ship inside `../migrations/` so they're versioned alongside the tables they protect — files here document *intent* per table/context). See [docs/planning/04-database-architecture.md §4](../../../docs/planning/04-database-architecture.md#4-row-level-security-rls).

**Status:** Phase 0 stub — empty. RLS is deny-by-default on every table from Phase 1 onward; positive + negative tests are a merge requirement (see [docs/planning/09-cross-cutting.md](../../../docs/planning/09-cross-cutting.md#testing-strategy)).
