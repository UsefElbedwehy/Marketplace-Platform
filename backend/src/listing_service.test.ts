import { assertEquals, assertRejects } from "jsr:@std/assert@^1";
import { createListing, fetchListings, updateListingStatus } from "./listing_service.ts";
import { AppError } from "./errors.ts";
import type { QueryExecutor, QueryResult } from "./query_executor.ts";

const CARS_ATTR_DEFS = [
  { id: "brand", key: "brand", data_type: "option", is_required: true },
  { id: "mileage", key: "mileage", data_type: "number", is_required: false },
];

function fakeExecutor(routes: Array<{ match: string; rows: unknown[] }>, calls: string[] = []): QueryExecutor {
  return {
    // deno-lint-ignore require-await
    async queryObject<T>(sql: string): Promise<QueryResult<T>> {
      calls.push(sql.trim().split("\n")[0]);
      const route = routes.find((r) => sql.includes(r.match));
      return { rows: (route?.rows ?? []) as T[] };
    },
  };
}

Deno.test("createListing rejects when a required attribute is missing", async () => {
  const db = fakeExecutor([{ match: "join catalog.attribute_group", rows: CARS_ATTR_DEFS }]);
  const err = await assertRejects(
    () => createListing(db, "owner-1", "tenant-1", { categoryId: "cars", title: "2019 BMW", attributes: {} }),
    AppError,
  );
  assertEquals(err.status, 422);
  assertEquals(err.fields?.[0].field, "brand");
  assertEquals(err.fields?.[0].code, "required");
});

Deno.test("createListing rejects an unknown option value with a field error, not a 500", async () => {
  const db = fakeExecutor([
    { match: "join catalog.attribute_group", rows: CARS_ATTR_DEFS },
    { match: "from catalog.attribute_option where attribute_id", rows: [] }, // no matching option
  ]);
  const err = await assertRejects(
    () => createListing(db, "owner-1", "tenant-1", { categoryId: "cars", title: "2019 BMW", attributes: { brand: "not-a-real-brand" } }),
    AppError,
  );
  assertEquals(err.status, 422);
  assertEquals(err.fields?.[0].code, "invalid_option");
});

Deno.test("createListing rejects a non-numeric value for a number attribute", async () => {
  const db = fakeExecutor([
    { match: "join catalog.attribute_group", rows: CARS_ATTR_DEFS },
    { match: "from catalog.attribute_option where attribute_id", rows: [{ id: "opt-bmw" }] },
  ]);
  const err = await assertRejects(
    () => createListing(db, "owner-1", "tenant-1", { categoryId: "cars", title: "2019 BMW", attributes: { brand: "bmw", mileage: "a lot" } }),
    AppError,
  );
  assertEquals(err.fields?.[0].field, "mileage");
  assertEquals(err.fields?.[0].code, "invalid_type");
});

Deno.test("createListing succeeds and returns the created listing when values are valid", async () => {
  const calls: string[] = [];
  const db = fakeExecutor(
    [
      { match: "join catalog.attribute_group", rows: CARS_ATTR_DEFS },
      { match: "from catalog.attribute_option where attribute_id", rows: [{ id: "opt-bmw" }] },
      { match: "insert into listing.listing (", rows: [{ id: "listing-1" }] },
      {
        match: "from listing.listing where id",
        rows: [{
          id: "listing-1", category_id: "cars", title: "2019 BMW", description: null,
          price: "85000", currency: "SAR", status: "draft", attributes_index: { brand: "bmw" }, created_at: "2026-01-01T00:00:00Z",
        }],
      },
    ],
    calls,
  );

  const record = await createListing(db, "owner-1", "tenant-1", {
    categoryId: "cars",
    title: "2019 BMW",
    price: 85000,
    currency: "SAR",
    attributes: { brand: "bmw", mileage: 84000 },
  });

  assertEquals(record.id, "listing-1");
  assertEquals(record.price, 85000);
  // one insert for the listing row + one for each resolved attribute value (brand, mileage)
  assertEquals(calls.filter((c) => c.startsWith("insert into listing.listing_attribute_value")).length, 2);
});

Deno.test("fetchListings rejects a filter key with unsafe characters (SQL-injection guard)", async () => {
  const db = fakeExecutor([]);
  await assertRejects(
    () => fetchListings(db, { attributes: { "brand'; drop table listing.listing; --": "bmw" } }),
    AppError,
  );
});

Deno.test("fetchListings compiles equality and range filters, and paginates via cursor", async () => {
  const calls: string[] = [];
  const capturedParams: unknown[][] = [];
  const db: QueryExecutor = {
    // deno-lint-ignore require-await
    async queryObject<T>(sql: string, args?: unknown[]) {
      calls.push(sql);
      capturedParams.push(args ?? []);
      return { rows: [] as T[] };
    },
  };
  await fetchListings(db, {
    categoryId: "cars",
    attributes: { brand: "bmw", mileage: { lt: 100000 } },
    cursor: "2026-01-01T00:00:00Z",
    limit: 10,
  });

  const sql = calls[0];
  assertEquals(sql.includes("category_id = $2"), true);
  assertEquals(sql.includes("attributes_index @> $3::jsonb"), true);
  assertEquals(sql.includes("(attributes_index ->> 'mileage')::numeric < $4"), true);
  assertEquals(sql.includes("created_at < $5"), true);
  assertEquals(sql.includes("limit 11"), true); // limit + 1, for hasMore detection
});

Deno.test("fetchListings with ownerId and no explicit status returns every status (no status condition)", async () => {
  const calls: string[] = [];
  const db: QueryExecutor = {
    // deno-lint-ignore require-await
    async queryObject<T>(sql: string) {
      calls.push(sql);
      return { rows: [] as T[] };
    },
  };
  await fetchListings(db, { ownerId: "owner-1" });
  assertEquals(calls[0].includes("owner_id = $1"), true);
  assertEquals(calls[0].includes("status ="), false);
});

Deno.test("fetchListings with an explicit status (moderation queue) filters by it, ignoring the published default", async () => {
  const calls: string[] = [];
  const db: QueryExecutor = {
    // deno-lint-ignore require-await
    async queryObject<T>(sql: string, args?: unknown[]) {
      calls.push(sql);
      void args;
      return { rows: [] as T[] };
    },
  };
  await fetchListings(db, { status: "pending_review" });
  assertEquals(calls[0].includes("status = $1"), true);
});

Deno.test("updateListingStatus allows a legal owner transition (draft -> pending_review)", async () => {
  const db = fakeExecutor([
    {
      match: "from listing.listing where id",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "draft", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
    {
      match: "update listing.listing set status",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "pending_review", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
  ]);
  const record = await updateListingStatus(db, "l1", false, "pending_review");
  assertEquals(record.status, "pending_review");
});

Deno.test("updateListingStatus rejects an illegal transition (draft -> published, skipping review)", async () => {
  const db = fakeExecutor([
    {
      match: "from listing.listing where id",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "draft", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
  ]);
  const err = await assertRejects(() => updateListingStatus(db, "l1", true, "published"), AppError);
  assertEquals(err.status, 422);
  assertEquals(err.code, "invalid_transition");
});

Deno.test("updateListingStatus rejects a non-moderator approving a listing", async () => {
  const db = fakeExecutor([
    {
      match: "from listing.listing where id",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "pending_review", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
  ]);
  const err = await assertRejects(() => updateListingStatus(db, "l1", false, "published"), AppError);
  assertEquals(err.status, 403);
});

Deno.test("updateListingStatus allows a moderator to approve a pending listing", async () => {
  const db = fakeExecutor([
    {
      match: "from listing.listing where id",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "pending_review", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
    {
      match: "update listing.listing set status",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "published", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
  ]);
  const record = await updateListingStatus(db, "l1", true, "published");
  assertEquals(record.status, "published");
});

Deno.test("updateListingStatus surfaces RLS silently filtering the UPDATE as a 404, not a false success", async () => {
  const db = fakeExecutor([
    {
      match: "from listing.listing where id",
      rows: [{ id: "l1", category_id: "cars", title: "t", description: null, price: null, currency: null, status: "pending_review", attributes_index: {}, created_at: "2026-01-01T00:00:00Z" }],
    },
    { match: "update listing.listing set status", rows: [] }, // RLS filtered it out
  ]);
  const err = await assertRejects(() => updateListingStatus(db, "l1", true, "published"), AppError);
  assertEquals(err.status, 404);
});
