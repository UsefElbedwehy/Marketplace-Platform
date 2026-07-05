// POST /v1/chat/conversations, GET /v1/chat/conversations,
// GET/POST /v1/chat/conversations/{id}/messages — buyer↔seller chat ⭐
// (Phase 6 golden-path exit criterion). RLS (conversation/message policies,
// migration 20260705120000) is the actual participant-isolation gate; this
// layer turns "you're not enabled for chat" into a clean 404 and shapes
// requests/responses to the contract. Reads are poll-based REST, not
// Supabase Realtime — see the migration's header for why.

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { fetchActiveConfig } from "../../../src/config_service.ts";
import { requireModuleEnabled } from "../../../src/module_gate.ts";
import {
  fetchConversations,
  fetchMessages,
  markMessagesRead,
  sendMessage,
  startOrGetConversation,
} from "../../../src/chat_service.ts";

const conversationsPattern = new URLPattern({ pathname: "/v1/chat/conversations" });
const messagesPattern = new URLPattern({ pathname: "/v1/chat/conversations/:id/messages" });

function requireTenant(tenantId: string | undefined): string {
  if (!tenantId) {
    throw new AppError(422, "validation_failed", "Session is missing a tenant context.");
  }
  return tenantId;
}

export async function handleChatRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);
    const tenantId = requireTenant(claims.tenant_id);

    if (req.method === "GET" && conversationsPattern.test(url)) {
      const conversations = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "chat");
        return await fetchConversations(client);
      });
      return withCors(jsonResponse(200, { data: conversations }));
    }

    if (req.method === "POST" && conversationsPattern.test(url)) {
      const body = await req.json();
      if (!body.listingId) {
        throw new AppError(422, "validation_failed", "listingId is required.", [
          { field: "listingId", code: "required", message: "listingId is required" },
        ]);
      }
      const conversation = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "chat");
        return await startOrGetConversation(client, claims.sub, tenantId, body.listingId);
      });
      return withCors(jsonResponse(201, { data: conversation }));
    }

    const messagesMatch = messagesPattern.exec(url);
    if (req.method === "GET" && messagesMatch) {
      const conversationId = messagesMatch.pathname.groups.id!;
      const messages = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "chat");
        const rows = await fetchMessages(client, conversationId);
        await markMessagesRead(client, conversationId, claims.sub);
        return rows;
      });
      return withCors(jsonResponse(200, { data: messages }));
    }

    if (req.method === "POST" && messagesMatch) {
      const conversationId = messagesMatch.pathname.groups.id!;
      const body = await req.json();
      const message = await withRequestContext(claims, async (client) => {
        requireModuleEnabled(await fetchActiveConfig(client), "chat");
        return await sendMessage(client, claims.sub, tenantId, conversationId, body.body);
      });
      return withCors(jsonResponse(201, { data: message }));
    }

    throw new AppError(404, "not_found", `No route for ${req.method} ${url.pathname}`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleChatRequest);
}
