import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { compile } from "json-schema-to-typescript";
import openapiTS, { astToString } from "openapi-typescript";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..", "..", "..");
const SCHEMA_DIR = path.join(REPO_ROOT, "contract", "schema");
const OPENAPI_PATH = path.join(REPO_ROOT, "contract", "openapi", "v1", "openapi.yaml");
const OUT_DIR = path.join(__dirname, "..", "generated");

const HEADER = `/**
 * AUTO-GENERATED — do not edit by hand.
 * Source: contract/schema/*.schema.json and contract/openapi/v1/openapi.yaml
 * Regenerate: npm run generate --workspace=packages/contract-types
 * See contract/README.md for what these files mean.
 */

`;

const SCHEMA_TARGETS = [
  { file: "app.schema.json", typeName: "AppConfig", outFile: "app.d.ts" },
  { file: "config.schema.json", typeName: "RuntimeConfig", outFile: "config.d.ts" },
  { file: "theme.schema.json", typeName: "ThemeTokens", outFile: "theme.d.ts" },
];

async function generateSchemaTypes() {
  const outDir = path.join(OUT_DIR, "schema");
  fs.mkdirSync(outDir, { recursive: true });

  const exports = [];
  for (const { file, typeName, outFile } of SCHEMA_TARGETS) {
    const schema = JSON.parse(fs.readFileSync(path.join(SCHEMA_DIR, file), "utf-8"));
    // json-schema-to-typescript names the root interface after `$id`/`title` when
    // present, ignoring the `name` argument — drop both so our chosen typeName wins.
    delete schema.title;
    delete schema.$id;
    const ts = await compile(schema, typeName, {
      cwd: SCHEMA_DIR,
      bannerComment: "",
      additionalProperties: false,
      style: { singleQuote: true },
    });
    fs.writeFileSync(path.join(outDir, outFile), HEADER + ts);
    exports.push({ typeName, outFile });
  }
  return exports;
}

async function generateApiTypes() {
  fs.mkdirSync(OUT_DIR, { recursive: true });
  const ast = await openapiTS(pathToFileURL(OPENAPI_PATH));
  const ts = astToString(ast);
  fs.writeFileSync(path.join(OUT_DIR, "api.d.ts"), HEADER + ts);
}

function generateIndex(schemaExports) {
  const lines = [
    HEADER.trimEnd(),
    "",
    ...schemaExports.map(
      ({ typeName, outFile }) => `export type { ${typeName} } from "./schema/${outFile.replace(".d.ts", "")}.js";`
    ),
    'export type { paths as ApiPaths, components as ApiComponents } from "./api.js";',
    "",
  ];
  fs.writeFileSync(path.join(OUT_DIR, "index.d.ts"), lines.join("\n"));
  // A trivial JS companion so `main`/bare-specifier imports resolve at runtime too (types are the real payload).
  fs.writeFileSync(path.join(OUT_DIR, "index.js"), "export {};\n");
}

async function main() {
  const schemaExports = await generateSchemaTypes();
  await generateApiTypes();
  generateIndex(schemaExports);
  console.log(`Generated contract types into ${path.relative(REPO_ROOT, OUT_DIR)}/`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
