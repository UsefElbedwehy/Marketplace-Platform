import type { QueryExecutor } from "./query_executor.ts";
import { AppError } from "./errors.ts";

export interface ConfigBundle {
  version: number;
  document: Record<string, unknown>;
}

export async function fetchActiveConfig(db: QueryExecutor): Promise<ConfigBundle> {
  const result = await db.queryObject<ConfigBundle>(
    "select version, document from config.bundle where is_active limit 1",
  );
  if (result.rows.length === 0) {
    throw new AppError(404, "not_found", "No active configuration found for this tenant.");
  }
  return result.rows[0];
}

export async function fetchActiveTheme(db: QueryExecutor): Promise<ConfigBundle> {
  const result = await db.queryObject<ConfigBundle>(
    "select version, document from config.theme where is_active limit 1",
  );
  if (result.rows.length === 0) {
    throw new AppError(404, "not_found", "No active theme found for this tenant.");
  }
  return result.rows[0];
}

// Publishing (Config/Theme Studio, docs/planning/06-dashboard-architecture.md §4):
// deactivate the current row, insert the next version as active — history and
// rollback come for free rather than mutating a row in place.
async function publish(db: QueryExecutor, table: "config.bundle" | "config.theme", tenantId: string, document: Record<string, unknown>): Promise<ConfigBundle> {
  await db.queryObject(`update ${table} set is_active = false where tenant_id = $1 and is_active`, [tenantId]);
  const result = await db.queryObject<ConfigBundle>(
    `insert into ${table} (tenant_id, version, document, is_active)
     select $1, coalesce((select max(version) from ${table} where tenant_id = $1), 0) + 1, $2::jsonb, true
     returning version, document`,
    [tenantId, JSON.stringify(document)],
  );
  return result.rows[0];
}

export function publishConfig(db: QueryExecutor, tenantId: string, document: Record<string, unknown>): Promise<ConfigBundle> {
  return publish(db, "config.bundle", tenantId, document);
}

export function publishTheme(db: QueryExecutor, tenantId: string, document: Record<string, unknown>): Promise<ConfigBundle> {
  return publish(db, "config.theme", tenantId, document);
}
