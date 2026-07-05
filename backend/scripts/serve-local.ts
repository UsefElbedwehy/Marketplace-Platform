// Local dev gateway — NOT how production works. In a real deployment each
// function group under supabase/functions/ deploys standalone (Supabase's
// own router dispatches /functions/v1/<name>). Locally, without Docker
// (see backend/README.md), this combines every handler behind one process
// on one port so local development and the dashboard have a single base URL
// to hit. Every handler is imported unchanged from its real function file —
// this script adds routing only, no duplicated logic.

import { handleConfigRequest } from "../supabase/functions/v1-config/index.ts";
import { handleThemeRequest } from "../supabase/functions/v1-theme/index.ts";
import { handleDevAuthRequest } from "../supabase/functions/v1-dev-auth/index.ts";
import { handleCatalogRequest } from "../supabase/functions/v1-catalog/index.ts";
import { handleListingsRequest } from "../supabase/functions/v1-listings/index.ts";
import { handleUsersRequest } from "../supabase/functions/v1-users/index.ts";
import { handleChatRequest } from "../supabase/functions/v1-chat/index.ts";
import { handleFavoritesRequest } from "../supabase/functions/v1-favorites/index.ts";
import { handleReviewsRequest } from "../supabase/functions/v1-reviews/index.ts";
import { handleNotificationsRequest } from "../supabase/functions/v1-notifications/index.ts";
import { handleProfilesRequest } from "../supabase/functions/v1-profiles/index.ts";

const PORT = Number(Deno.env.get("PORT") ?? "8000");

async function router(req: Request): Promise<Response> {
  const url = new URL(req.url);

  if (url.pathname === "/v1/config") return await handleConfigRequest(req);
  if (url.pathname === "/v1/theme") return await handleThemeRequest(req);
  if (url.pathname === "/v1/dev-auth") return await handleDevAuthRequest(req);
  if (url.pathname === "/v1/health") {
    return new Response(JSON.stringify({ status: "ok" }), { headers: { "content-type": "application/json" } });
  }
  if (
    url.pathname.startsWith("/v1/categories") ||
    url.pathname.startsWith("/v1/attributes") ||
    url.pathname.startsWith("/v1/attribute-groups")
  ) {
    return await handleCatalogRequest(req);
  }
  if (url.pathname === "/v1/listings" || url.pathname.startsWith("/v1/listings/")) return await handleListingsRequest(req);
  if (url.pathname === "/v1/users" || url.pathname.startsWith("/v1/users/")) return await handleUsersRequest(req);
  if (url.pathname.startsWith("/v1/chat/")) return await handleChatRequest(req);
  if (url.pathname === "/v1/favorites" || url.pathname.startsWith("/v1/favorites/")) return await handleFavoritesRequest(req);
  if (url.pathname === "/v1/reviews") return await handleReviewsRequest(req);
  if (url.pathname === "/v1/notifications" || url.pathname.startsWith("/v1/notifications/")) return await handleNotificationsRequest(req);
  if (url.pathname.startsWith("/v1/profiles/")) return await handleProfilesRequest(req);

  return new Response(JSON.stringify({ error: { code: "not_found", message: `No route for ${url.pathname}` } }), {
    status: 404,
    headers: { "content-type": "application/json" },
  });
}

console.log(`Local dev gateway listening on http://localhost:${PORT}`);
Deno.serve({ port: PORT }, router);
