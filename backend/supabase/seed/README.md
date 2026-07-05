# Seed data

SQL seed files, applied in filename order (`00_`, `01_`, …) by `supabase db reset` per `config.toml`'s `db.seed.sql_paths = ["./seed/*.sql"]`.

**Status:** Phase 0 stub — empty. Phase 1 adds the default runtime config/theme seed; Phase 2 adds the default reference marketplace (the full category/attribute tree described in [docs/planning/05-dynamic-schema-engine.md §9](../../../docs/planning/05-dynamic-schema-engine.md#9-the-v1-golden-path-what-done-proves)).

Planned files:
- `00_reference_config.sql` — installs the merged `configs/clients/default` config/theme as the seeded row in `config.*` tables (Phase 1).
- `01_reference_catalog.sql` — installs the default category tree + Cars/Apartments/Phones attribute schemas (Phase 2).
