// Listing create + filter ⭐ — the other half of the Dynamic Category &
// Attribute Engine's contract. Validates submitted attribute values against
// catalog.attribute definitions at the request level (field-level errors, a
// much better UX than a raw Postgres exception) — the DB trigger
// (listing.enforce_attribute_value_type) remains the authoritative backstop
// per ADR-0003 ("the database enforces truth, Edge Functions enforce
// workflow"). Filtering compiles against listing.attributes_index, the same
// JSONB projection docs/planning/05-dynamic-schema-engine.md §7 describes.

import type { QueryExecutor } from "./query_executor.ts";
import { AppError, type FieldError } from "./errors.ts";

export interface CreateListingInput {
  categoryId: string;
  title: string;
  description?: string;
  price?: number;
  currency?: string;
  attributes: Record<string, unknown>;
}

export interface ListingRecord {
  id: string;
  ownerId: string;
  categoryId: string;
  title: string;
  description: string | null;
  price: number | null;
  currency: string | null;
  status: string;
  attributesIndex: Record<string, unknown>;
  createdAt: string;
}

interface AttributeDef {
  id: string;
  key: string;
  data_type: string;
  is_required: boolean;
}

const KEY_PATTERN = /^[a-zA-Z0-9_]+$/;

async function fetchCategoryAttributeDefs(db: QueryExecutor, categoryId: string): Promise<AttributeDef[]> {
  const result = await db.queryObject<AttributeDef>(
    `select a.id, a.key, a.data_type, a.is_required
     from catalog.attribute a
     join catalog.attribute_group g on g.id = a.group_id
     where g.category_id = $1 and a.is_active`,
    [categoryId],
  );
  return result.rows;
}

interface ResolvedValue {
  attributeId: string;
  column: "value_text" | "value_number" | "value_bool" | "value_date" | "value_option_id" | "value_option_ids" | "value_json";
  value: unknown;
}

async function resolveAttributeValues(
  db: QueryExecutor,
  attrDefs: AttributeDef[],
  submitted: Record<string, unknown>,
): Promise<{ resolved: ResolvedValue[]; fieldErrors: FieldError[] }> {
  const resolved: ResolvedValue[] = [];
  const fieldErrors: FieldError[] = [];

  for (const def of attrDefs) {
    const raw = submitted[def.key];
    if (raw === undefined || raw === null || raw === "") {
      if (def.is_required) {
        fieldErrors.push({ field: def.key, code: "required", message: `${def.key} is required` });
      }
      continue;
    }

    switch (def.data_type) {
      case "text":
        resolved.push({ attributeId: def.id, column: "value_text", value: String(raw) });
        break;
      case "number": {
        const num = Number(raw);
        if (Number.isNaN(num)) {
          fieldErrors.push({ field: def.key, code: "invalid_type", message: `${def.key} must be a number` });
          break;
        }
        resolved.push({ attributeId: def.id, column: "value_number", value: num });
        break;
      }
      case "bool":
        resolved.push({ attributeId: def.id, column: "value_bool", value: Boolean(raw) });
        break;
      case "date":
        resolved.push({ attributeId: def.id, column: "value_date", value: String(raw) });
        break;
      case "option": {
        const optRows = await db.queryObject<{ id: string }>(
          "select id from catalog.attribute_option where attribute_id = $1 and value = $2 and is_active",
          [def.id, String(raw)],
        );
        if (optRows.rows.length === 0) {
          fieldErrors.push({ field: def.key, code: "invalid_option", message: `"${raw}" is not a valid option for ${def.key}` });
          break;
        }
        resolved.push({ attributeId: def.id, column: "value_option_id", value: optRows.rows[0].id });
        break;
      }
      case "option_multi": {
        const values = (Array.isArray(raw) ? raw : [raw]).map(String);
        const optRows = await db.queryObject<{ id: string }>(
          "select id from catalog.attribute_option where attribute_id = $1 and value = any($2) and is_active",
          [def.id, values],
        );
        if (optRows.rows.length !== values.length) {
          fieldErrors.push({ field: def.key, code: "invalid_option", message: `One or more values are not valid options for ${def.key}` });
          break;
        }
        resolved.push({ attributeId: def.id, column: "value_option_ids", value: optRows.rows.map((r) => r.id) });
        break;
      }
      default:
        resolved.push({ attributeId: def.id, column: "value_json", value: raw });
    }
  }

  return { resolved, fieldErrors };
}

export async function createListing(
  db: QueryExecutor,
  ownerId: string,
  tenantId: string,
  input: CreateListingInput,
): Promise<ListingRecord> {
  const attrDefs = await fetchCategoryAttributeDefs(db, input.categoryId);

  if (attrDefs.length === 0) {
    const catCheck = await db.queryObject<{ id: string }>("select id from catalog.category where id = $1", [input.categoryId]);
    if (catCheck.rows.length === 0) {
      throw new AppError(404, "not_found", `Category ${input.categoryId} not found.`);
    }
  }

  if (!input.title || input.title.trim().length === 0) {
    throw new AppError(422, "validation_failed", "title is required.", [
      { field: "title", code: "required", message: "title is required" },
    ]);
  }

  const { resolved, fieldErrors } = await resolveAttributeValues(db, attrDefs, input.attributes ?? {});
  if (fieldErrors.length > 0) {
    throw new AppError(422, "validation_failed", "One or more attribute values are invalid.", fieldErrors);
  }

  const insertResult = await db.queryObject<{ id: string }>(
    `insert into listing.listing (tenant_id, owner_id, category_id, title, description, price, currency)
     values ($1, $2, $3, $4, $5, $6, $7)
     returning id`,
    [tenantId, ownerId, input.categoryId, input.title, input.description ?? null, input.price ?? null, input.currency ?? null],
  );
  const listingId = insertResult.rows[0].id;

  for (const rv of resolved) {
    const columns = {
      value_text: null as unknown,
      value_number: null as unknown,
      value_bool: null as unknown,
      value_date: null as unknown,
      value_option_id: null as unknown,
      value_option_ids: null as unknown,
      value_json: null as unknown,
    };
    columns[rv.column] = rv.column === "value_json" ? JSON.stringify(rv.value) : rv.value;

    try {
      await db.queryObject(
        `insert into listing.listing_attribute_value
           (listing_id, attribute_id, value_text, value_number, value_bool, value_date, value_option_id, value_option_ids, value_json)
         values ($1, $2, $3, $4, $5, $6, $7, $8, $9::jsonb)`,
        [
          listingId,
          rv.attributeId,
          columns.value_text,
          columns.value_number,
          columns.value_bool,
          columns.value_date,
          columns.value_option_id,
          columns.value_option_ids,
          columns.value_json,
        ],
      );
    } catch (e) {
      // The DB trigger (validation min/max/pattern) is the authoritative backstop;
      // this surfaces its rejection as a normal field-level error instead of a 500.
      const message = e instanceof Error ? e.message : "Invalid attribute value.";
      throw new AppError(422, "validation_failed", message, [{ field: rv.attributeId, code: "invalid", message }]);
    }
  }

  return await fetchListingById(db, listingId);
}

function mapListingRow(r: {
  id: string;
  owner_id: string;
  category_id: string;
  title: string;
  description: string | null;
  price: string | number | null;
  currency: string | null;
  status: string;
  attributes_index: Record<string, unknown>;
  created_at: string;
}): ListingRecord {
  return {
    id: r.id,
    ownerId: r.owner_id,
    categoryId: r.category_id,
    title: r.title,
    description: r.description,
    price: r.price !== null ? Number(r.price) : null,
    currency: r.currency,
    status: r.status,
    attributesIndex: r.attributes_index,
    createdAt: r.created_at,
  };
}

export async function fetchListingById(db: QueryExecutor, id: string): Promise<ListingRecord> {
  const result = await db.queryObject<Parameters<typeof mapListingRow>[0]>(
    "select id, owner_id, category_id, title, description, price, currency, status, attributes_index, created_at from listing.listing where id = $1",
    [id],
  );
  if (result.rows.length === 0) {
    throw new AppError(404, "not_found", `Listing ${id} not found.`);
  }
  return mapListingRow(result.rows[0]);
}

// === Moderation ===============================================================
// RLS (listing_update_own_or_moderator) is the actual row-access gate — owner
// or moderator, enforced at the database. This layer adds the *workflow* on
// top: which status-to-status transitions are legal at all, and which
// specific targets (approving/rejecting) require moderator privilege even
// though RLS would otherwise let a moderator touch the row regardless. See
// docs/planning/09-cross-cutting.md's "DB enforces truth, Edge Functions
// enforce workflow" split.

const ALLOWED_TRANSITIONS: Record<string, string[]> = {
  draft: ["pending_review"],
  pending_review: ["draft", "published", "rejected"],
  published: ["archived", "sold"],
  rejected: ["draft"],
  archived: ["draft"],
  sold: [],
};

const MODERATOR_ONLY_TARGETS = new Set(["published", "rejected"]);

export async function updateListingStatus(
  db: QueryExecutor,
  listingId: string,
  isModerator: boolean,
  newStatus: string,
): Promise<ListingRecord> {
  const current = await fetchListingById(db, listingId);

  const allowed = ALLOWED_TRANSITIONS[current.status] ?? [];
  if (!allowed.includes(newStatus)) {
    throw new AppError(
      422,
      "invalid_transition",
      `Cannot transition from "${current.status}" to "${newStatus}".`,
      [{ field: "status", code: "invalid_transition", message: `"${current.status}" -> "${newStatus}" is not allowed` }],
    );
  }
  if (MODERATOR_ONLY_TARGETS.has(newStatus) && !isModerator) {
    throw new AppError(403, "forbidden", `Only a moderator can set status to "${newStatus}".`);
  }

  const result = await db.queryObject<Parameters<typeof mapListingRow>[0]>(
    `update listing.listing set status = $1, updated_at = now() where id = $2
     returning id, owner_id, category_id, title, description, price, currency, status, attributes_index, created_at`,
    [newStatus, listingId],
  );
  if (result.rows.length === 0) {
    // RLS silently filtered the row out (not the owner, not a moderator) —
    // see backend/tests/README.md's note on UPDATE vs INSERT RLS behavior.
    throw new AppError(404, "not_found", `Listing ${listingId} not found or not editable by you.`);
  }
  return mapListingRow(result.rows[0]);
}

export interface AttributeRangeFilter {
  gte?: number;
  lte?: number;
  gt?: number;
  lt?: number;
}

export interface ListingFilters {
  categoryId?: string;
  status?: string;
  /** "Mine"/moderation views: when set with no explicit `status`, returns every status for that owner instead of defaulting to published-only. */
  ownerId?: string;
  attributes?: Record<string, string | number | boolean | AttributeRangeFilter>;
  cursor?: string;
  limit?: number;
}

const RANGE_OPS: Record<string, string> = { gte: ">=", lte: "<=", gt: ">", lt: "<" };

export async function fetchListings(
  db: QueryExecutor,
  filters: ListingFilters,
): Promise<{ items: ListingRecord[]; nextCursor: string | null }> {
  const conditions: string[] = [];
  const params: unknown[] = [];

  // Public browsing (no status, no owner scoping) defaults to published-only.
  // A "mine"/moderation view (ownerId set, or an explicit status like
  // pending_review) asks for whatever it asks for — RLS is what actually
  // restricts which rows come back either way.
  if (filters.status) {
    params.push(filters.status);
    conditions.push(`status = $${params.length}`);
  } else if (!filters.ownerId) {
    params.push("published");
    conditions.push(`status = $${params.length}`);
  }

  if (filters.ownerId) {
    params.push(filters.ownerId);
    conditions.push(`owner_id = $${params.length}`);
  }

  if (filters.categoryId) {
    params.push(filters.categoryId);
    conditions.push(`category_id = $${params.length}`);
  }

  if (filters.attributes) {
    for (const [key, val] of Object.entries(filters.attributes)) {
      if (!KEY_PATTERN.test(key)) {
        throw new AppError(422, "validation_failed", `Invalid filter key "${key}".`, [
          { field: key, code: "invalid_key", message: "Filter keys may only contain letters, numbers, and underscores." },
        ]);
      }
      if (val !== null && typeof val === "object") {
        for (const [op, num] of Object.entries(val as AttributeRangeFilter)) {
          const sqlOp = RANGE_OPS[op];
          if (!sqlOp || typeof num !== "number") continue;
          params.push(num);
          conditions.push(`(attributes_index ->> '${key}')::numeric ${sqlOp} $${params.length}`);
        }
      } else {
        params.push(JSON.stringify({ [key]: val }));
        conditions.push(`attributes_index @> $${params.length}::jsonb`);
      }
    }
  }

  if (filters.cursor) {
    params.push(filters.cursor);
    conditions.push(`created_at < $${params.length}`);
  }

  const limit = Math.min(filters.limit ?? 20, 100);
  const result = await db.queryObject<Parameters<typeof mapListingRow>[0]>(
    `select id, owner_id, category_id, title, description, price, currency, status, attributes_index, created_at
     from listing.listing
     where ${conditions.join(" and ")}
     order by created_at desc
     limit ${limit + 1}`,
    params,
  );

  const hasMore = result.rows.length > limit;
  const items = result.rows.slice(0, limit).map(mapListingRow);
  const nextCursor = hasMore ? items[items.length - 1].createdAt : null;
  return { items, nextCursor };
}
