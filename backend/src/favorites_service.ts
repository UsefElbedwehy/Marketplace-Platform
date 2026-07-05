// A buyer's saved listings (docs/planning/04-database-architecture.md §4:
// "Favorites | owner only | owner only"). Add/remove are both idempotent —
// PUT/DELETE on /v1/favorites/{listingId}, not a single ambiguous "toggle"
// endpoint whose result depends on client-side state that could drift from
// the server on a double-tap.

import type { QueryExecutor } from "./query_executor.ts";

export interface Favorite {
  id: string;
  listingId: string;
  createdAt: string;
}

function mapFavoriteRow(r: { id: string; listing_id: string; created_at: string }): Favorite {
  return { id: r.id, listingId: r.listing_id, createdAt: r.created_at };
}

export async function addFavorite(db: QueryExecutor, userId: string, tenantId: string, listingId: string): Promise<Favorite> {
  const result = await db.queryObject<Parameters<typeof mapFavoriteRow>[0]>(
    `insert into social.favorite (tenant_id, user_id, listing_id) values ($1, $2, $3)
     on conflict (user_id, listing_id) do update set user_id = excluded.user_id
     returning id, listing_id, created_at`,
    [tenantId, userId, listingId],
  );
  return mapFavoriteRow(result.rows[0]);
}

// Idempotent: removing a listing that isn't favorited (or isn't yours, via
// RLS) is a harmless no-op, not an error.
export async function removeFavorite(db: QueryExecutor, listingId: string): Promise<void> {
  await db.queryObject(`delete from social.favorite where listing_id = $1`, [listingId]);
}

// No explicit user_id filter — RLS's favorite_all_own already scopes this to
// the caller's own rows.
export async function fetchFavorites(db: QueryExecutor): Promise<Favorite[]> {
  const result = await db.queryObject<Parameters<typeof mapFavoriteRow>[0]>(
    `select id, listing_id, created_at from social.favorite order by created_at desc`,
  );
  return result.rows.map(mapFavoriteRow);
}
