import { assertEquals, assertRejects } from "jsr:@std/assert@^1";
import { fetchProfileById, fetchProfiles, updateUserRole } from "./user_service.ts";
import { AppError } from "./errors.ts";
import type { QueryExecutor, QueryResult } from "./query_executor.ts";

function fakeExecutor(routes: Array<{ match: string; rows: unknown[] }>): QueryExecutor {
  return {
    // deno-lint-ignore require-await
    async queryObject<T>(sql: string): Promise<QueryResult<T>> {
      const route = routes.find((r) => sql.includes(r.match));
      return { rows: (route?.rows ?? []) as T[] };
    },
  };
}

const PROFILE_ROW = { id: "u1", email: "buyer@test.local", display_name: "Buyer", app_role: "buyer", created_at: "2026-01-01T00:00:00Z" };

Deno.test("fetchProfiles maps joined rows to the contract shape", async () => {
  const db = fakeExecutor([{ match: "join auth.users", rows: [PROFILE_ROW] }]);
  const profiles = await fetchProfiles(db);
  assertEquals(profiles, [
    { id: "u1", email: "buyer@test.local", displayName: "Buyer", appRole: "buyer", createdAt: "2026-01-01T00:00:00Z" },
  ]);
});

Deno.test("fetchProfileById throws 404 when not found", async () => {
  const db = fakeExecutor([{ match: "where p.id", rows: [] }]);
  await assertRejects(() => fetchProfileById(db, "missing"), AppError);
});

Deno.test("updateUserRole rejects an invalid role", async () => {
  const db = fakeExecutor([]);
  const err = await assertRejects(() => updateUserRole(db, "admin-1", "u1", "superhero"), AppError);
  assertEquals(err.status, 422);
});

Deno.test("updateUserRole rejects an actor changing their own role", async () => {
  const db = fakeExecutor([]);
  const err = await assertRejects(() => updateUserRole(db, "admin-1", "admin-1", "super_admin"), AppError);
  assertEquals(err.status, 403);
});

Deno.test("updateUserRole surfaces RLS silently filtering the UPDATE as a 404", async () => {
  const db = fakeExecutor([{ match: "update identity.profile set app_role", rows: [] }]);
  const err = await assertRejects(() => updateUserRole(db, "buyer-1", "u2", "seller"), AppError);
  assertEquals(err.status, 404);
});

Deno.test("updateUserRole succeeds and returns the updated profile", async () => {
  const db = fakeExecutor([
    { match: "update identity.profile set app_role", rows: [{ id: "u1" }] },
    { match: "join auth.users", rows: [{ ...PROFILE_ROW, app_role: "seller" }] },
  ]);
  const profile = await updateUserRole(db, "admin-1", "u1", "seller");
  assertEquals(profile.appRole, "seller");
});
