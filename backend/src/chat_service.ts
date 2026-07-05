// Buyer↔seller chat on a listing ⭐ (Phase 6 golden-path exit criterion).
// Conversations/messages persist in Postgres exactly as docs/planning/
// 03-backend-architecture.md §6 describes; only the read transport differs
// from the plan — real Supabase Realtime needs the hosted/Docker Realtime
// service, unavailable here, so v1-chat exposes plain REST poll endpoints
// instead (see the schema migration's header for the fuller note). Message
// sends still go through this service (validation + notification fan-out),
// exactly as designed.

import type { QueryExecutor } from "./query_executor.ts";
import { AppError } from "./errors.ts";
import { createNotification } from "./notifications_service.ts";

export interface Conversation {
  id: string;
  listingId: string;
  listingTitle: string;
  buyerId: string;
  buyerDisplayName: string | null;
  sellerId: string;
  sellerDisplayName: string | null;
  lastMessageAt: string | null;
  createdAt: string;
}

interface ConversationRow {
  id: string;
  listing_id: string;
  listing_title: string;
  buyer_id: string;
  buyer_display_name: string | null;
  seller_id: string;
  seller_display_name: string | null;
  last_message_at: string | null;
  created_at: string;
}

function mapConversationRow(r: ConversationRow): Conversation {
  return {
    id: r.id,
    listingId: r.listing_id,
    listingTitle: r.listing_title,
    buyerId: r.buyer_id,
    buyerDisplayName: r.buyer_display_name,
    sellerId: r.seller_id,
    sellerDisplayName: r.seller_display_name,
    lastMessageAt: r.last_message_at,
    createdAt: r.created_at,
  };
}

const CONVERSATION_SELECT = `
  select c.id, c.listing_id, l.title as listing_title,
         c.buyer_id, buyer.display_name as buyer_display_name,
         c.seller_id, seller.display_name as seller_display_name,
         c.last_message_at, c.created_at
  from social.conversation c
  join listing.listing l on l.id = c.listing_id
  join identity.profile buyer on buyer.id = c.buyer_id
  join identity.profile seller on seller.id = c.seller_id
`;

export interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  body: string;
  readAt: string | null;
  createdAt: string;
}

function mapMessageRow(r: {
  id: string;
  conversation_id: string;
  sender_id: string;
  body: string;
  read_at: string | null;
  created_at: string;
}): Message {
  return {
    id: r.id,
    conversationId: r.conversation_id,
    senderId: r.sender_id,
    body: r.body,
    readAt: r.read_at,
    createdAt: r.created_at,
  };
}

export async function fetchConversationById(db: QueryExecutor, conversationId: string): Promise<Conversation> {
  const result = await db.queryObject<ConversationRow>(`${CONVERSATION_SELECT} where c.id = $1`, [conversationId]);
  if (result.rows.length === 0) {
    throw new AppError(404, "not_found", `Conversation ${conversationId} not found or not yours.`);
  }
  return mapConversationRow(result.rows[0]);
}

// No explicit buyer/seller filter — RLS's conversation_select_participant
// already scopes this to conversations the caller participates in.
export async function fetchConversations(db: QueryExecutor): Promise<Conversation[]> {
  const result = await db.queryObject<ConversationRow>(
    `${CONVERSATION_SELECT} order by coalesce(c.last_message_at, c.created_at) desc`,
  );
  return result.rows.map(mapConversationRow);
}

// Buyer-initiated only — a seller can't proactively start a thread with a
// buyer through this endpoint, matching how classifieds chat actually works
// (the interested party reaches out first). Re-opening chat about a listing
// you've already messaged the seller about resumes that same conversation
// (unique(listing_id, buyer_id) at the DB level).
export async function startOrGetConversation(
  db: QueryExecutor,
  buyerId: string,
  tenantId: string,
  listingId: string,
): Promise<Conversation> {
  const listingResult = await db.queryObject<{ owner_id: string }>(
    `select owner_id from listing.listing where id = $1`,
    [listingId],
  );
  if (listingResult.rows.length === 0) {
    throw new AppError(404, "not_found", `Listing ${listingId} not found.`);
  }
  const sellerId = listingResult.rows[0].owner_id;
  if (sellerId === buyerId) {
    throw new AppError(422, "validation_failed", "You cannot start a conversation about your own listing.", [
      { field: "listingId", code: "own_listing", message: "cannot message yourself about your own listing" },
    ]);
  }

  const existing = await db.queryObject<{ id: string }>(
    `select id from social.conversation where listing_id = $1 and buyer_id = $2`,
    [listingId, buyerId],
  );
  if (existing.rows.length > 0) {
    return await fetchConversationById(db, existing.rows[0].id);
  }

  const created = await db.queryObject<{ id: string }>(
    `insert into social.conversation (tenant_id, listing_id, buyer_id, seller_id) values ($1, $2, $3, $4) returning id`,
    [tenantId, listingId, buyerId, sellerId],
  );
  return await fetchConversationById(db, created.rows[0].id);
}

export async function fetchMessages(db: QueryExecutor, conversationId: string, limit = 100): Promise<Message[]> {
  const result = await db.queryObject<Parameters<typeof mapMessageRow>[0]>(
    `select id, conversation_id, sender_id, body, read_at, created_at
     from social.message
     where conversation_id = $1
     order by created_at asc
     limit $2`,
    [conversationId, Math.min(limit, 500)],
  );
  return result.rows.map(mapMessageRow);
}

export async function sendMessage(
  db: QueryExecutor,
  senderId: string,
  tenantId: string,
  conversationId: string,
  body: string,
): Promise<Message> {
  if (!body || body.trim().length === 0) {
    throw new AppError(422, "validation_failed", "body is required.", [
      { field: "body", code: "required", message: "body is required" },
    ]);
  }
  if (body.length > 4000) {
    throw new AppError(422, "validation_failed", "body must be at most 4000 characters.", [
      { field: "body", code: "too_long", message: "body must be at most 4000 characters" },
    ]);
  }

  const result = await db.queryObject<Parameters<typeof mapMessageRow>[0]>(
    `insert into social.message (conversation_id, sender_id, body) values ($1, $2, $3)
     returning id, conversation_id, sender_id, body, read_at, created_at`,
    [conversationId, senderId, body],
  );
  const message = mapMessageRow(result.rows[0]);

  const conversation = await fetchConversationById(db, conversationId);
  const isSenderBuyer = conversation.buyerId === senderId;
  const recipientId = isSenderBuyer ? conversation.sellerId : conversation.buyerId;
  const senderName = isSenderBuyer ? conversation.buyerDisplayName : conversation.sellerDisplayName;

  await createNotification(db, {
    tenantId,
    userId: recipientId,
    type: "chat_message",
    payload: { conversationId, messageId: message.id, listingId: conversation.listingId },
    pushTitle: senderName ?? "New message",
    pushBody: body.length > 120 ? `${body.slice(0, 117)}...` : body,
  });

  return message;
}

export async function markMessagesRead(db: QueryExecutor, conversationId: string, readerId: string): Promise<void> {
  await db.queryObject(
    `update social.message set read_at = now()
     where conversation_id = $1 and sender_id <> $2 and read_at is null`,
    [conversationId, readerId],
  );
}
