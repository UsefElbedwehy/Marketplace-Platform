// GET /v1/users, PATCH /v1/users/{id} — the dashboard's Users screen
// (docs/planning/06-dashboard-architecture.md). RLS (profile_select_own_or_admin,
// profile_update_admin) is the actual row-access gate; the app-level checks
// here just turn "you're not an admin so RLS quietly gave you nothing" into
// a clean 403 for this admin-only screen, and enforce "never your own role"
// (backend/src/user_service.ts).

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims, type Claims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { fetchProfiles, updateUserRole } from "../../../src/user_service.ts";

const ADMIN_ROLES = new Set(["admin", "super_admin"]);
const userByIdPattern = new URLPattern({ pathname: "/v1/users/:id" });

function requireAdmin(claims: Claims): void {
  if (!claims.app_role || !ADMIN_ROLES.has(claims.app_role)) {
    throw new AppError(403, "forbidden", "Only an admin can manage users.");
  }
}

export async function handleUsersRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);
    requireAdmin(claims);

    if (req.method === "GET" && url.pathname === "/v1/users") {
      const profiles = await withRequestContext(claims, (client) => fetchProfiles(client));
      return withCors(jsonResponse(200, { data: profiles }));
    }

    const patchMatch = req.method === "PATCH" ? userByIdPattern.exec(url) : null;
    if (patchMatch) {
      const targetUserId = patchMatch.pathname.groups.id!;
      const body = await req.json();
      if (!body.appRole) {
        throw new AppError(422, "validation_failed", "appRole is required.", [
          { field: "appRole", code: "required", message: "appRole is required" },
        ]);
      }
      const profile = await withRequestContext(
        claims,
        (client) => updateUserRole(client, claims.sub, targetUserId, body.appRole),
      );
      return withCors(jsonResponse(200, { data: profile }));
    }

    throw new AppError(405, "method_not_allowed", `${req.method} is not supported on ${url.pathname}.`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleUsersRequest);
}
