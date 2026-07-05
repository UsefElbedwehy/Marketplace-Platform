// GET /v1/profiles/{userId} — a seller's PUBLIC profile ⭐ (Phase 6
// golden-path exit criterion: "view a seller profile"). Deliberately
// separate from v1-users (admin-only role management) — this is a public,
// read-only lookup with no admin gate. Not module-flag-gated: there's no
// dedicated `modules.*` entry for "seller profile viewing" in the
// Development Schema (it's a natural extension of browsing listings, not an
// independently toggleable capability like chat/favorites/reviews) — inventing
// one just for this endpoint would be scope creep beyond what config.json
// actually models today.

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { fetchPublicSellerProfile } from "../../../src/seller_profile_service.ts";

const profileByIdPattern = new URLPattern({ pathname: "/v1/profiles/:id" });

export async function handleProfilesRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);

    const match = req.method === "GET" ? profileByIdPattern.exec(url) : null;
    if (match) {
      const sellerId = match.pathname.groups.id!;
      const profile = await withRequestContext(claims, (client) => fetchPublicSellerProfile(client, sellerId));
      return withCors(jsonResponse(200, { data: profile }));
    }

    throw new AppError(404, "not_found", `No route for ${req.method} ${url.pathname}`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleProfilesRequest);
}
