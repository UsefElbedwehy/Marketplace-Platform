import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const GENERATED_DIR = path.join(__dirname, "..", "generated");

test("generated output exists and exports the expected root types", () => {
  const files = ["index.d.ts", "api.d.ts", "schema/app.d.ts", "schema/config.d.ts", "schema/theme.d.ts"];
  for (const file of files) {
    assert.ok(fs.existsSync(path.join(GENERATED_DIR, file)), `expected ${file} to exist (run 'npm run generate')`);
  }

  const app = fs.readFileSync(path.join(GENERATED_DIR, "schema", "app.d.ts"), "utf-8");
  const config = fs.readFileSync(path.join(GENERATED_DIR, "schema", "config.d.ts"), "utf-8");
  const theme = fs.readFileSync(path.join(GENERATED_DIR, "schema", "theme.d.ts"), "utf-8");
  const api = fs.readFileSync(path.join(GENERATED_DIR, "api.d.ts"), "utf-8");

  assert.match(app, /export interface AppConfig/);
  assert.match(config, /export interface RuntimeConfig/);
  assert.match(theme, /export interface ThemeTokens/);
  assert.match(api, /export interface paths/);
  assert.match(api, /"\/v1\/config"/);
  assert.match(api, /"\/v1\/theme"/);
});
