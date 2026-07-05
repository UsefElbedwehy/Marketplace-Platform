// Local-dev data-access adapter: a direct Postgres connection, with the
// connection itself performing the SET ROLE + request.jwt.claims dance that
// PostgREST performs per-request in a real Supabase deployment. This is what
// lets RLS apply faithfully even without PostgREST/GoTrue running (no Docker
// available — see backend/README.md).
//
// PRODUCTION NOTE: a real deployment would swap this module's internals for
// `@supabase/supabase-js` (`.from()`/`.rpc()` against PostgREST, scoped to
// the caller's JWT) without changing any call site — every repository in
// backend/src/ depends only on withRequestContext's signature, not on how it
// talks to Postgres. See docs/planning/03-backend-architecture.md and
// ADR-0002 for why the contract, not this adapter, is the portable asset.

import { Pool, type PoolClient } from "postgres";
import type { Claims } from "./auth.ts";
import { AppError } from "../../../src/errors.ts";

// Postgres errors that mean something specific and user-facing (RLS
// rejection, a broken foreign key, a duplicate) get mapped to a clean 4xx
// AppError instead of leaking as an "internal_error" 500 — an RLS policy
// correctly blocking a write is an expected, not exceptional, outcome from
// the caller's point of view.
const PG_ERROR_CODE_MAP: Record<string, { status: number; code: string; message: string }> = {
  "42501": { status: 403, code: "forbidden", message: "You do not have permission to perform this action." },
  "23503": { status: 422, code: "validation_failed", message: "This references a record that does not exist." },
  "23505": { status: 409, code: "conflict", message: "A record with this value already exists." },
};

function mapPostgresError(e: unknown): unknown {
  // AppErrors thrown intentionally by a service (e.g. field-level validation
  // failures) must pass through unchanged — only raw driver errors get mapped.
  if (e instanceof AppError) return e;
  const code = (e as { fields?: { code?: string } })?.fields?.code;
  const mapped = code ? PG_ERROR_CODE_MAP[code] : undefined;
  return mapped ? new AppError(mapped.status, mapped.code, mapped.message) : e;
}

const pool = new Pool(
  {
    user: Deno.env.get("PGUSER") ?? "usefelbedwehy",
    database: Deno.env.get("PGDATABASE") ?? "marketplace_platform_dev",
    hostname: Deno.env.get("PGHOST") ?? "localhost",
    port: Number(Deno.env.get("PGPORT") ?? "5432"),
  },
  Number(Deno.env.get("PGPOOL_SIZE") ?? "10"),
  true,
);

/**
 * Runs `fn` with a client whose session has been switched to the caller's
 * Postgres role and whose request.jwt.claims mirrors their token — so every
 * query `fn` issues is subject to the same RLS policies a real PostgREST
 * request would be. Wrapped in a transaction so SET LOCAL is scoped correctly
 * and a thrown error rolls back any partial writes.
 */
export async function withRequestContext<T>(claims: Claims, fn: (client: PoolClient) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.queryObject("begin");
    // `claims.role` is restricted to a known enum by auth.ts's runtime
    // validation before it ever reaches here — safe to interpolate since SET
    // does not support bind parameters for identifiers/role names.
    await client.queryObject(`set local role ${claims.role}`);
    await client.queryObject("select set_config('request.jwt.claims', $1, true)", [JSON.stringify(claims)]);
    const result = await fn(client);
    await client.queryObject("commit");
    return result;
  } catch (e) {
    await client.queryObject("rollback").catch(() => {});
    throw mapPostgresError(e);
  } finally {
    client.release();
  }
}

export async function closePool(): Promise<void> {
  await pool.end();
}

export type { PoolClient };
