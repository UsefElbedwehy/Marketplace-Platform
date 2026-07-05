import fs from "node:fs";
import path from "node:path";
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { SCHEMA_DIR } from "./paths.js";
import { toPartialSchema } from "./schemaUtils.js";

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf-8"));
}

const SCHEMA_FILES = ["common.schema.json", "app.schema.json", "config.schema.json", "theme.schema.json"];

/**
 * Builds a single Ajv instance holding, for each document schema
 * (app/config/theme): the full schema (for `default` docs and merged
 * results) and a partial variant (for client/env overlay documents).
 * `common.schema.json` is registered once, referenced by $ref from the rest.
 */
export function loadSchemas() {
  const ajv = new Ajv2020({ allErrors: true, strict: true });
  addFormats(ajv);

  const documents = {};
  for (const file of SCHEMA_FILES) {
    documents[file] = readJson(path.join(SCHEMA_DIR, file));
  }

  ajv.addSchema(documents["common.schema.json"]);

  const validators = {};
  for (const file of ["app.schema.json", "config.schema.json", "theme.schema.json"]) {
    const full = documents[file];
    ajv.addSchema(full);
    const partial = toPartialSchema(full);
    ajv.addSchema(partial);

    const key = file.replace(".schema.json", "");
    validators[key] = {
      full: ajv.getSchema(full.$id),
      partial: ajv.getSchema(partial.$id),
    };
  }

  return validators;
}

export function formatErrors(errors) {
  return (errors ?? [])
    .map((e) => `  - ${e.instancePath || "(root)"} ${e.message}${e.params ? ` [${JSON.stringify(e.params)}]` : ""}`)
    .join("\n");
}
