#!/usr/bin/env node
import { validateAll } from "./validate.js";

function parseArgs(argv) {
  const args = { client: null, env: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--client") args.client = argv[++i];
    else if (argv[i] === "--env") args.env = argv[++i];
  }
  return args;
}

const { client, env } = parseArgs(process.argv.slice(2));
const results = validateAll({ onlyClient: client, onlyEnv: env });

let failures = 0;
for (const r of results) {
  if (r.ok) {
    console.log(`ok    ${r.label}`);
  } else {
    failures++;
    console.error(`FAIL  ${r.label}`);
    console.error(r.errors);
  }
}

console.log(`\n${results.length - failures}/${results.length} checks passed.`);
if (failures > 0) {
  console.error(`${failures} check(s) failed.`);
  process.exit(1);
}
