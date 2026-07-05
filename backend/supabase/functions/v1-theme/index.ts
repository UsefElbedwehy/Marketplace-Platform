// GET/PATCH /v1/theme — contract/openapi/v1/openapi.yaml's `getTheme`
// operation, plus the Theme Studio's publish path (RLS-gated to admins).

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { matchesIfNoneMatch, versionETag } from "../_shared/etag.ts";
import { fetchActiveTheme, publishTheme } from "../../../src/config_service.ts";

export async function handleThemeRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  try {
    const claims = await resolveClaims(req);

    if (req.method === "GET") {
      const bundle = await withRequestContext(claims, (client) => fetchActiveTheme(client));
      const etag = versionETag(bundle.version);
      if (matchesIfNoneMatch(req, etag)) {
        return withCors(new Response(null, { status: 304, headers: { etag } }));
      }
      return withCors(jsonResponse(200, { data: bundle.document }, { etag }));
    }

    if (req.method === "PATCH") {
      if (!claims.tenant_id) {
        throw new AppError(422, "validation_failed", "Session is missing a tenant context.");
      }
      const document = await req.json();
      const bundle = await withRequestContext(claims, (client) => publishTheme(client, claims.tenant_id!, document));
      return withCors(jsonResponse(200, { data: bundle.document }, { etag: versionETag(bundle.version) }));
    }

    throw new AppError(405, "method_not_allowed", `${req.method} is not supported on /v1/theme.`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleThemeRequest);
}
