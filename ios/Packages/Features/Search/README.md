# Features/Search

Dynamic filters, category-scoped results, and pagination — the other half of the golden path, proving the *same* field-type registry that drives the create-listing form also drives search. See [docs/planning/05-dynamic-schema-engine.md §6](../../../../docs/planning/05-dynamic-schema-engine.md#6-dynamic-form-rendering-client) and [ROADMAP.md](../../../../docs/ROADMAP.md#phase-4--ios-golden-path-dynamicforms--listings-).

**Status:** implemented and tested (`swift test` — 8/8 passing; `xcodebuild build -scheme Search` confirmed). Depends on Core, DomainKit, DesignSystem, DynamicForms. Deliberately does **not** depend on `Features/Listings` (Feature isolation — `tooling/lint/boundaries.sh`-enforced).

- **`SearchViewModel`** — one cohesive view model for the whole tab: `leafCategories` (flattened from the category tree), `selectedCategory`, `schema`, `equalityFormState: DynamicFormState?` (built from `Self.equalityOnlySchema(from:)` — a schema copy containing only `isFilterable && dataType != .number` fields), `rangeValues: [String: AttributeRangeFilter]` for the number fields the equality form can't represent, and a cursor-paginated `results`.
- **`FilterSheetView`** — combines `DynamicFormView(state: equalityFormState)` (option/bool filters, via the exact same renderer `CreateListingView` uses) with a `ForEach` of **`RangeFilterRow`** for each filterable number field (a separate min/max UI, since a single-value `DynamicFormState` field has no notion of a range).
- **`SearchResultRowView`** — intentionally a near-duplicate of `Listings.ListingRowView`, not shared, per the Feature-isolation tradeoff explained in `Features/Listings/README.md`.
- **`SearchView`** — flat leaf-category list → results, with `.cancellationAction`/`.confirmationAction` toolbar placements (not `.navigationBarLeading`/`.navigationBarTrailing`, which are iOS-only and fail to compile against this package's `.macOS(.v14)` test target).

## Verification

Exercised end-to-end by `ios/App/UITests/GoldenPathUITests.swift`: after a Car listing is created and published through `Features/Listings`' moderation flow, this package's Search tab filters Cars by `brand = BMW` and confirms the listing surfaces — proving the dynamic filter genuinely round-trips through the real backend (JSONB `attributes_index` filtering), not a client-side stub.
