// A seller's PUBLIC profile ⭐ (Phase 6 golden-path exit criterion: "view a
// seller profile") — deliberately a separate service from user_service.ts,
// which is the admin-only role-management CRUD (docs/planning/06-dashboard-
// architecture.md's Users screen). This one is read-only, has no admin gate,
// and only ever selects public-safe columns (never app_role/tenant_id).
// identity.profile's RLS was widened (profile_select_public, migration
// 20260705120100) to allow this — safe because clients never query Postgres
// directly (ADR-0002); only this shaped response reaches them.

import type { QueryExecutor } from "./query_executor.ts";
import { AppError } from "./errors.ts";

export interface PublicSellerProfile {
  id: string;
  displayName: string | null;
  avatarUrl: string | null;
  bio: string | null;
  memberSince: string;
  ratingCount: number;
  ratingAverage: number | null;
  publishedListingCount: number;
}

export async function fetchPublicSellerProfile(db: QueryExecutor, sellerId: string): Promise<PublicSellerProfile> {
  const result = await db.queryObject<{
    id: string;
    display_name: string | null;
    avatar_url: string | null;
    bio: string | null;
    created_at: string;
    rating_count: number;
    rating_sum: number;
    published_listing_count: string;
  }>(
    `select p.id, p.display_name, p.avatar_url, p.bio, p.created_at, p.rating_count, p.rating_sum,
            (select count(*) from listing.listing l where l.owner_id = p.id and l.status = 'published') as published_listing_count
     from identity.profile p
     where p.id = $1`,
    [sellerId],
  );
  if (result.rows.length === 0) {
    throw new AppError(404, "not_found", `Seller ${sellerId} not found.`);
  }
  const r = result.rows[0];
  return {
    id: r.id,
    displayName: r.display_name,
    avatarUrl: r.avatar_url,
    bio: r.bio,
    memberSince: r.created_at,
    ratingCount: r.rating_count,
    ratingAverage: r.rating_count > 0 ? Math.round((r.rating_sum / r.rating_count) * 10) / 10 : null,
    publishedListingCount: Number(r.published_listing_count),
  };
}
