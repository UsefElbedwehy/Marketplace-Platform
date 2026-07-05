import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** Absolute path to the monorepo root (packages/config-validation/src -> ../../..). */
export const REPO_ROOT = path.resolve(__dirname, "..", "..", "..");

export const SCHEMA_DIR = path.join(REPO_ROOT, "contract", "schema");
export const CONFIGS_DIR = path.join(REPO_ROOT, "configs");
export const CLIENTS_DIR = path.join(CONFIGS_DIR, "clients");

export const ENV_NAMES = ["development", "staging", "production"];

/** app.json is never merged — every client must supply a complete document (see ADR-0004). */
export const APP_FILE = "app.json";
/** config.json and theme.json deep-merge: default <- client overlay <- env overlay. */
export const MERGED_FILES = ["config.json", "theme.json"];
