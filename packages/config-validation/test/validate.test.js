import test from "node:test";
import assert from "node:assert/strict";
import { validateAll } from "../src/validate.js";
import { deepMerge } from "../src/merge.js";
import { stripRequiredRecursively } from "../src/schemaUtils.js";

test("all real configs in the repo validate cleanly", () => {
  const results = validateAll({});
  const failures = results.filter((r) => !r.ok);
  if (failures.length > 0) {
    const detail = failures.map((f) => `${f.label}:\n${f.errors}`).join("\n");
    assert.fail(`${failures.length} config check(s) failed:\n${detail}`);
  }
  assert.ok(results.length > 0, "expected at least one check to run");
});

test("default client alone validates (mirrors `config-validate --client default`)", () => {
  const results = validateAll({ onlyClient: "default" });
  assert.ok(results.every((r) => r.ok), "default client must be fully valid standalone");
});

test("deepMerge overrides nested keys without discarding siblings", () => {
  const base = { a: { x: 1, y: 2 }, b: [1, 2, 3] };
  const overlay = { a: { y: 99 }, b: [9] };
  const merged = deepMerge(base, overlay);
  assert.deepEqual(merged, { a: { x: 1, y: 99 }, b: [9] });
});

test("deepMerge leaves base untouched when overlay omits a key", () => {
  const base = { a: 1, b: 2 };
  const merged = deepMerge(base, { b: 3 });
  assert.equal(merged.a, 1);
  assert.equal(merged.b, 3);
});

test("stripRequiredRecursively removes nested required arrays", () => {
  const schema = {
    required: ["a"],
    properties: {
      a: { type: "object", required: ["b"], properties: { b: { type: "string" } } },
    },
  };
  stripRequiredRecursively(schema);
  assert.equal(schema.required, undefined);
  assert.equal(schema.properties.a.required, undefined);
});
