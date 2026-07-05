// GET /v1/favorites, PUT/DELETE /v1/favorites/{listingId} — a buyer's saved
// listings. RLS (favorite_all_own) is the actual owner-isolation gate.

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { fetchActiveConfig } from "../../../src/config_service.ts";
import { requireModuleEnabled } from "../../../src/module_gate.ts";
import { addFavorite, fetchFavorites, removeFavorite } from "../../../src/favorites_service.ts";

const favoritesPattern = new URLPattern({ pathname: "/v1/favorites" });
const favoriteByListingPattern = new URLPattern({ pathname: "/v1/favorites/:listingId" });

function requireTenant(tenantId: string | undefined): string {
  if (!tenantId) {
    throw new AppError(422, "validation_failed", "Session is missing a tenant context.");
  }
  return tenantId;
}

export async function handleFavoritesRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);
    const tenantId = requireTenant(claims.tenant_id);

    if (req.method === "GET" && favoritesPattern.test(url)) {
      const favorites = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "favorites");
        return await fetchFavorites(client);
      });
      return withCors(jsonResponse(200, { data: favorites }));
    }

    const byListingMatch = favoriteByListingPattern.exec(url);
    if (req.method === "PUT" && byListingMatch) {
      const listingId = byListingMatch.pathname.groups.listingId!;
      const favorite = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "favorites");
        return await addFavorite(client, claims.sub, tenantId, listingId);
      });
      return withCors(jsonResponse(200, { data: favorite }));
    }

    if (req.method === "DELETE" && byListingMatch) {
      const listingId = byListingMatch.pathname.groups.listingId!;
      await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "favorites");
        await removeFavorite(client, listingId);
      });
      return withCors(new Response(null, { status: 204 }));
    }

    throw new AppError(404, "not_found", `No route for ${req.method} ${url.pathname}`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleFavoritesRequest);
}
