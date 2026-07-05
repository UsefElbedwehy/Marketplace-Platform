# @marketplace-platform/contract-types

Generates TypeScript types **from** the contract (`contract/schema/*.schema.json` + `contract/openapi/v1/openapi.yaml`), for the Next.js dashboard and the backend's Deno/TS Edge Functions to consume. This is what keeps "the contract is the source of truth" true for TypeScript consumers — nobody hand-writes a `RuntimeConfig` interface that can drift from the real schema.

## Usage

```bash
npm run generate --workspace=packages/contract-types   # regenerate generated/
npm run typecheck:contract-types                        # tsc --noEmit against the output
```

Output (committed, not gitignored, so it's immediately importable before any consumer package exists):

```
generated/
├── index.d.ts        # barrel re-exporting everything below
├── api.d.ts           # `paths` / `components` from the OpenAPI spec (openapi-typescript)
└── schema/
    ├── app.d.ts       # AppConfig      (build-time slice)
    ├── config.d.ts    # RuntimeConfig  (runtime slice)
    └── theme.d.ts     # ThemeTokens    (semantic design tokens)
```

## CI drift check

Because the output is committed, CI regenerates it and runs `git diff --exit-code -- packages/contract-types/generated` — if a schema change wasn't followed by regeneration, the build fails loudly rather than letting a stale type silently diverge from the contract.

## A codegen gotcha worth knowing

`json-schema-to-typescript` names the root exported interface after the schema's `$id` or `title` when present, **ignoring** the `name` argument you pass to `compile()`. `src/generate.js` deletes both before compiling so the root type is named `AppConfig`/`RuntimeConfig`/`ThemeTokens` as intended — otherwise you'd get interfaces named after the schema's `$id` URL.

A second gotcha caught by `npm run typecheck:contract-types` during Phase 0: an object schema that mixes **named optional properties** with a **typed `additionalProperties`** (e.g. `additionalProperties: { "type": "boolean" }`) compiles to TypeScript that `tsc --strict` rejects (`TS2411`) — an optional property's `T | undefined` isn't assignable to a stricter index signature's `T`. Fixed in `contract/schema/config.schema.json` by closing `modules` (`additionalProperties: false` — it's meant to be a fixed, code-backed capability set anyway) while leaving `featureFlags` genuinely open-ended. If you add a new object schema with both named properties and a typed catch-all, expect the same error and ask whether the catch-all should really be open-ended.
