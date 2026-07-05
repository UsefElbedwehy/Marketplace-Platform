import fs from "node:fs";
import path from "node:path";
import { loadSchemas, formatErrors } from "./schemas.js";
import { deepMerge } from "./merge.js";
import { CLIENTS_DIR, CONFIGS_DIR, ENV_NAMES, APP_FILE, MERGED_FILES } from "./paths.js";

function readJsonIfExists(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, "utf-8"));
}

function listClients() {
  return fs
    .readdirSync(CLIENTS_DIR, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name)
    .sort();
}

function check(label, validateFn, doc) {
  if (!validateFn) return fail(label, "schema validator not found");
  const valid = validateFn(doc);
  return { label, ok: valid, errors: valid ? null : formatErrors(validateFn.errors) };
}

function fail(label, message) {
  return { label, ok: false, errors: `  - ${message}` };
}

/**
 * Merges base (default docs) <- overlay (client docs, optional) <- the named
 * environment's overlay (if present on disk), per key ("config" | "theme").
 */
function mergeForEnv({ base, overlay, env }) {
  const merged = {};
  for (const key of Object.keys(base)) {
    if (!base[key]) continue;
    let doc = base[key];
    if (overlay && overlay[key]) doc = deepMerge(doc, overlay[key]);
    const envDoc = readJsonIfExists(path.join(CONFIGS_DIR, env, `${key}.json`));
    if (envDoc) doc = deepMerge(doc, envDoc);
    merged[key] = doc;
  }
  return merged;
}

/**
 * Validates:
 *  1. Every client's app.json as a complete, standalone document (never merged).
 *  2. `default`'s config.json/theme.json as complete, standalone documents.
 *  3. Every non-default client's config.json/theme.json as structurally-valid
 *     partial overlays.
 *  4. Every (client x environment) *effective* merged config.json/theme.json
 *     as a complete document — this is what the backend would actually serve.
 *  5. Every environment overlay file as a structurally-valid partial overlay.
 */
export function validateAll({ onlyClient, onlyEnv } = {}) {
  const schemas = loadSchemas();
  const results = [];
  const clients = onlyClient ? [onlyClient] : listClients();
  const envs = onlyEnv ? [onlyEnv] : ENV_NAMES;

  const defaultDocs = {};
  for (const file of MERGED_FILES) {
    defaultDocs[file.replace(".json", "")] = readJsonIfExists(path.join(CLIENTS_DIR, "default", file));
  }

  for (const client of clients) {
    const clientDir = path.join(CLIENTS_DIR, client);
    if (!fs.existsSync(clientDir)) {
      results.push(fail(`clients/${client}`, `client directory not found: ${clientDir}`));
      continue;
    }

    const appDoc = readJsonIfExists(path.join(clientDir, APP_FILE));
    if (!appDoc) {
      results.push(fail(`clients/${client}/${APP_FILE}`, "missing required file"));
    } else {
      results.push(check(`clients/${client}/${APP_FILE} (complete)`, schemas.app.full, appDoc));
    }

    const isDefault = client === "default";
    const clientDocs = {};
    for (const file of MERGED_FILES) {
      const key = file.replace(".json", "");
      const doc = readJsonIfExists(path.join(clientDir, file));
      clientDocs[key] = doc;
      if (!doc) {
        results.push(fail(`clients/${client}/${file}`, "missing required file"));
        continue;
      }
      const validator = isDefault ? schemas[key].full : schemas[key].partial;
      const label = isDefault ? `clients/${client}/${file} (complete)` : `clients/${client}/${file} (overlay)`;
      results.push(check(label, validator, doc));
    }

    for (const env of envs) {
      const merged = isDefault
        ? mergeForEnv({ base: clientDocs, env })
        : mergeForEnv({ base: defaultDocs, overlay: clientDocs, env });
      for (const key of Object.keys(merged)) {
        results.push(check(`effective[${client} + ${env}]/${key}.json`, schemas[key].full, merged[key]));
      }
    }
  }

  for (const env of envs) {
    for (const file of MERGED_FILES) {
      const key = file.replace(".json", "");
      const doc = readJsonIfExists(path.join(CONFIGS_DIR, env, file));
      if (doc) {
        results.push(check(`${env}/${file} (overlay)`, schemas[key].partial, doc));
      }
    }
  }

  return results;
}
