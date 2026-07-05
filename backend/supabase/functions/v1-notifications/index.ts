// GET /v1/notifications, PATCH /v1/notifications/{id} — the in-app
// notification list a client polls (docs/planning/03-backend-architecture.md
// §6's outbox, no Realtime transport here — see the schema migration's
// header). RLS (outbox_select_own, outbox_update_own) is the actual gate.

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { fetchActiveConfig } from "../../../src/config_service.ts";
import { requireModuleEnabled } from "../../../src/module_gate.ts";
import { fetchNotifications, markNotificationRead } from "../../../src/notifications_service.ts";

const notificationsPattern = new URLPattern({ pathname: "/v1/notifications" });
const notificationByIdPattern = new URLPattern({ pathname: "/v1/notifications/:id" });

export async function handleNotificationsRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);

    if (req.method === "GET" && notificationsPattern.test(url)) {
      const notifications = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "notifications");
        return await fetchNotifications(client);
      });
      return withCors(jsonResponse(200, { data: notifications }));
    }

    const byIdMatch = req.method === "PATCH" ? notificationByIdPattern.exec(url) : null;
    if (byIdMatch) {
      const notificationId = byIdMatch.pathname.groups.id!;
      const notification = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "notifications");
        return await markNotificationRead(client, notificationId);
      });
      return withCors(jsonResponse(200, { data: notification }));
    }

    throw new AppError(404, "not_found", `No route for ${req.method} ${url.pathname}`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleNotificationsRequest);
}
