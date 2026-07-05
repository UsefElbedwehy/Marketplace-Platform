# Modules

> Living document. Boundary rules: [planning/01-system-architecture.md §4](planning/01-system-architecture.md#4-module-boundaries--dependency-rules).

Each iOS feature module and each backend bounded context is documented here as it lands, with a link to its own `README/Architecture/Flow/API/Testing/Future.md` set.

**Status:** the iOS *foundation* packages (`Core`, `DomainKit`, `Networking`, `Configuration`, `DesignSystem`, `DataKit`) plus the Phase 4 golden-path packages (`DynamicForms`, `Features/Listings`, `Features/Search`) are implemented — one concise `README.md` per package (`ios/Packages/*/README.md`), the pattern this project has used consistently for non-feature modules (matches backend/dashboard), extended to `Features/*` too rather than the full README/Architecture/Flow/API/Testing/Future set, since each Feature package here is still small enough that one doc covers it without redundancy. `Features/Listings` and `Features/Search` never import each other (`tooling/lint/boundaries.sh`-enforced); both consume `DynamicForms`' field-type registry. Backend bounded contexts (`platform`, `identity`, `config`, `catalog` ⭐, `listing` ⭐) and the dashboard's screens (Schema Builder, Config Studio, Theme Studio, Listings, Users) are implemented — see [DATABASE.md](DATABASE.md), [BACKEND.md](BACKEND.md), and [dashboard/README.md](../dashboard/README.md).
