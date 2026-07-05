// GET /v1/reviews?sellerId=..., POST /v1/reviews — a buyer's rating of a
// seller. RLS (review_select_public, review_insert_reviewer) is the actual
// gate; reviews are public-read and insert-only (immutable feedback).

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { fetchActiveConfig } from "../../../src/config_service.ts";
import { requireModuleEnabled } from "../../../src/module_gate.ts";
import { createReview, fetchReviewsForSeller } from "../../../src/reviews_service.ts";

const reviewsPattern = new URLPattern({ pathname: "/v1/reviews" });

function requireTenant(tenantId: string | undefined): string {
  if (!tenantId) {
    throw new AppError(422, "validation_failed", "Session is missing a tenant context.");
  }
  return tenantId;
}

export async function handleReviewsRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);

    if (req.method === "GET" && reviewsPattern.test(url)) {
      const sellerId = url.searchParams.get("sellerId");
      if (!sellerId) {
        throw new AppError(422, "validation_failed", "sellerId is required.", [
          { field: "sellerId", code: "required", message: "sellerId is required" },
        ]);
      }
      const reviews = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "reviews");
        return await fetchReviewsForSeller(client, sellerId);
      });
      return withCors(jsonResponse(200, { data: reviews }));
    }

    if (req.method === "POST" && reviewsPattern.test(url)) {
      const tenantId = requireTenant(claims.tenant_id);
      const body = await req.json();
      const review = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "reviews");
        return await createReview(client, claims.sub, tenantId, body);
      });
      return withCors(jsonResponse(201, { data: review }));
    }

    throw new AppError(404, "not_found", `No route for ${req.method} ${url.pathname}`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleReviewsRequest);
}
