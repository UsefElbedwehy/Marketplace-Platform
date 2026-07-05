// A buyer's rating of a seller — immutable once posted (social.review has no
// update/delete RLS policy). social.review_bump_rating (DB trigger)
// maintains identity.profile's rating_count/rating_sum counters; the average
// is computed at read time here rather than stored, to avoid float drift.

import type { QueryExecutor } from "./query_executor.ts";
import { AppError } from "./errors.ts";

export interface Review {
  id: string;
  reviewerId: string;
  reviewerDisplayName: string | null;
  revieweeId: string;
  listingId: string | null;
  rating: number;
  comment: string | null;
  createdAt: string;
}

const REVIEW_SELECT = `
  select r.id, r.reviewer_id, p.display_name as reviewer_display_name, r.reviewee_id, r.listing_id, r.rating, r.comment, r.created_at
  from social.review r
  join identity.profile p on p.id = r.reviewer_id
`;

function mapReviewRow(r: {
  id: string;
  reviewer_id: string;
  reviewer_display_name: string | null;
  reviewee_id: string;
  listing_id: string | null;
  rating: number;
  comment: string | null;
  created_at: string;
}): Review {
  return {
    id: r.id,
    reviewerId: r.reviewer_id,
    reviewerDisplayName: r.reviewer_display_name,
    revieweeId: r.reviewee_id,
    listingId: r.listing_id,
    rating: r.rating,
    comment: r.comment,
    createdAt: r.created_at,
  };
}

export interface CreateReviewInput {
  revieweeId: string;
  listingId?: string;
  rating: number;
  comment?: string;
}

export async function createReview(db: QueryExecutor, reviewerId: string, tenantId: string, input: CreateReviewInput): Promise<Review> {
  if (!Number.isInteger(input.rating) || input.rating < 1 || input.rating > 5) {
    throw new AppError(422, "validation_failed", "rating must be an integer between 1 and 5.", [
      { field: "rating", code: "invalid_range", message: "rating must be an integer between 1 and 5" },
    ]);
  }
  if (input.revieweeId === reviewerId) {
    throw new AppError(422, "validation_failed", "You cannot review yourself.", [
      { field: "revieweeId", code: "invalid", message: "cannot equal the reviewer" },
    ]);
  }

  const result = await db.queryObject<{ id: string }>(
    `insert into social.review (tenant_id, reviewer_id, reviewee_id, listing_id, rating, comment)
     values ($1, $2, $3, $4, $5, $6)
     returning id`,
    [tenantId, reviewerId, input.revieweeId, input.listingId ?? null, input.rating, input.comment ?? null],
  );
  const review = await db.queryObject<Parameters<typeof mapReviewRow>[0]>(`${REVIEW_SELECT} where r.id = $1`, [result.rows[0].id]);
  return mapReviewRow(review.rows[0]);
}

export async function fetchReviewsForSeller(db: QueryExecutor, sellerId: string, limit = 20): Promise<Review[]> {
  const result = await db.queryObject<Parameters<typeof mapReviewRow>[0]>(
    `${REVIEW_SELECT} where r.reviewee_id = $1 order by r.created_at desc limit $2`,
    [sellerId, Math.min(limit, 100)],
  );
  return result.rows.map(mapReviewRow);
}
