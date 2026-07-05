# Migrations

Versioned, forward-only SQL migrations, applied in filename order by `supabase migration up` / CI. See [docs/planning/04-database-architecture.md §8](../../../docs/planning/04-database-architecture.md#8-migrations).

**Status:** Phase 0 stub — empty. Phase 1 adds the `platform`, `identity`, `config` schemas (tenancy + RLS scaffolding, config/theme tables); Phase 2 adds `catalog` and `listing` (the Dynamic Category & Attribute Engine).

No manual production edits — DB state must always be reproducible from migrations + [`../seed/`](../seed/README.md).
