# @marketplace-platform/config-validation

Validates every `configs/**` Development Schema document against the JSON Schema contract in `contract/schema/`. Makes "configuration is a validated artifact, not a runtime surprise" ([ADR-0004](../../docs/adr/0004-configuration-engine.md)) an executable fact, not a promise.

## What it checks

1. Every client's `app.json` as a **complete, standalone document** (never merged — see [contract/README.md](../../contract/README.md#development-schema-merge-model)).
2. `default`'s `config.json` / `theme.json` as **complete, standalone documents**.
3. Every other client's `config.json` / `theme.json` as **structurally-valid partial overlays** (same type/enum/format constraints, but nothing is required to be present).
4. Every **effective merged** `(client × environment)` `config.json` / `theme.json` — `default` ← client overlay ← env overlay — as a **complete document**. This is what the backend would actually serve.
5. Every environment overlay file (`configs/{development,staging,production}/config.json`) as a structurally-valid partial overlay.

## Usage

```bash
npm run validate --workspace=packages/config-validation          # validate everything
node packages/config-validation/src/cli.js --client default       # one client, all envs
node packages/config-validation/src/cli.js --client client_a --env production
```

Exit code is non-zero if any check fails — wired into CI (see `.github/workflows/`).

## How the partial-schema trick works

`src/schemaUtils.js#stripRequiredRecursively` deep-clones a full JSON Schema document and deletes every `required` array from it (at every nesting level), registering the clone under a derived `$id` (`<original>.partial`) in the same Ajv instance. `additionalProperties: false` and all type/enum/format constraints remain — so overlay files still get typo/type errors, they just aren't forced to restate the whole document.

## Files

| File | Responsibility |
|---|---|
| `src/paths.js` | Resolves repo-relative paths (schema dir, configs dir, known env names) |
| `src/schemaUtils.js` | Derives partial (required-stripped) schema variants |
| `src/merge.js` | Deep-merge (arrays replaced wholesale, not concatenated) |
| `src/schemas.js` | Loads `contract/schema/*.schema.json` into a single Ajv2020 instance |
| `src/validate.js` | Orchestrates the checks described above |
| `src/cli.js` | `--client` / `--env` scoped CLI entrypoint, non-zero exit on failure |

## Testing

`npm run test --workspace=packages/config-validation` — runs against the **real** `configs/` tree in this repo (not fixtures), so a broken config fails the same way in `npm test` as it would in `npm run validate`. Also covers the merge algorithm and the schema-stripping utility in isolation.
