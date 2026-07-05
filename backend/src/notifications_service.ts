// platform.outbox ⭐ (docs/planning/03-backend-architecture.md §6): the
// per-user notification record an in-app list reads (GET /v1/notifications),
// written by whichever service produced the triggering event — never a
// client, never a DB trigger, since creating a notification is orchestration
// (a provider call to PushPort) rather than a pure data invariant. See
// backend/src/ports/push_port.ts's header for why real APNs delivery is a
// documented gap here.

import type { QueryExecutor } from "./query_executor.ts";
import { AppError } from "./errors.ts";
import { LoggingPushAdapter, type PushPort } from "./ports/push_port.ts";

export type NotificationType = "chat_message" | "listing_favorited" | "review_received";

export interface Notification {
  id: string;
  type: NotificationType;
  payload: Record<string, unknown>;
  readAt: string | null;
  deliveredAt: string | null;
  createdAt: string;
}

function mapNotificationRow(r: {
  id: string;
  type: string;
  payload: Record<string, unknown>;
  read_at: string | null;
  delivered_at: string | null;
  created_at: string;
}): Notification {
  return {
    id: r.id,
    type: r.type as NotificationType,
    payload: r.payload,
    readAt: r.read_at,
    deliveredAt: r.delivered_at,
    createdAt: r.created_at,
  };
}

export interface CreateNotificationInput {
  tenantId: string;
  userId: string;
  type: NotificationType;
  payload: Record<string, unknown>;
  pushTitle: string;
  pushBody: string;
}

export async function createNotification(
  db: QueryExecutor,
  input: CreateNotificationInput,
  push: PushPort = new LoggingPushAdapter(),
): Promise<Notification> {
  const { delivered } = await push.send({
    userId: input.userId,
    title: input.pushTitle,
    body: input.pushBody,
    data: input.payload,
  });

  // No RETURNING: the recipient (input.userId) — not the caller creating
  // this notification as a side effect of their own action — is the only
  // one with SELECT visibility (per RLS) into this row, so id/created_at
  // are generated here instead of read back from the DB. See migration
  // 20260705120300's header for the bug this avoids.
  const id = crypto.randomUUID();
  const createdAt = new Date().toISOString();
  const deliveredAt = delivered ? createdAt : null;

  await db.queryObject(
    `insert into platform.outbox (id, tenant_id, user_id, type, payload, delivered_at, created_at)
     values ($1, $2, $3, $4, $5::jsonb, $6, $7)`,
    [id, input.tenantId, input.userId, input.type, JSON.stringify(input.payload), deliveredAt, createdAt],
  );

  return { id, type: input.type, payload: input.payload, readAt: null, deliveredAt, createdAt };
}

// No explicit `user_id = ...` filter: RLS's outbox_select_own already scopes
// this to the caller's own rows for anyone but service_role, the same
// let-RLS-filter pattern user_service.ts's fetchProfiles uses.
export async function fetchNotifications(db: QueryExecutor, limit = 50): Promise<Notification[]> {
  const result = await db.queryObject<Parameters<typeof mapNotificationRow>[0]>(
    `select id, type, payload, read_at, delivered_at, created_at
     from platform.outbox
     order by created_at desc
     limit $1`,
    [Math.min(limit, 100)],
  );
  return result.rows.map(mapNotificationRow);
}

export async function markNotificationRead(db: QueryExecutor, notificationId: string): Promise<Notification> {
  const result = await db.queryObject<Parameters<typeof mapNotificationRow>[0]>(
    `update platform.outbox set read_at = now() where id = $1
     returning id, type, payload, read_at, delivered_at, created_at`,
    [notificationId],
  );
  if (result.rows.length === 0) {
    // RLS silently filtered the row out (not the recipient) — see
    // backend/tests/README.md's note on UPDATE vs INSERT RLS behavior.
    throw new AppError(404, "not_found", `Notification ${notificationId} not found or not yours.`);
  }
  return mapNotificationRow(result.rows[0]);
}
