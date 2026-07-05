import { assertEquals, assertRejects } from "jsr:@std/assert@^1";
import { fetchActiveConfig, fetchActiveTheme } from "./config_service.ts";
import { AppError } from "./errors.ts";
import type { QueryExecutor, QueryResult } from "./query_executor.ts";

function fakeExecutor(rows: unknown[]): QueryExecutor {
  return {
    // deno-lint-ignore require-await
    async queryObject<T>(): Promise<QueryResult<T>> {
      return { rows: rows as T[] };
    },
  };
}

Deno.test("fetchActiveConfig returns the bundle when one exists", async () => {
  const db = fakeExecutor([{ version: 3, document: { clientId: "default" } }]);
  const bundle = await fetchActiveConfig(db);
  assertEquals(bundle.version, 3);
  assertEquals(bundle.document.clientId, "default");
});

Deno.test("fetchActiveConfig throws a 404 AppError when no active bundle exists", async () => {
  const db = fakeExecutor([]);
  const err = await assertRejects(() => fetchActiveConfig(db), AppError);
  assertEquals(err.status, 404);
  assertEquals(err.code, "not_found");
});

Deno.test("fetchActiveTheme returns the bundle when one exists", async () => {
  const db = fakeExecutor([{ version: 1, document: { clientId: "default" } }]);
  const bundle = await fetchActiveTheme(db);
  assertEquals(bundle.version, 1);
});

Deno.test("fetchActiveTheme throws a 404 AppError when no active theme exists", async () => {
  const db = fakeExecutor([]);
  await assertRejects(() => fetchActiveTheme(db), AppError);
});
