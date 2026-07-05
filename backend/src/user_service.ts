// User & role management ⭐ — the dashboard's "Users" screen
// (docs/planning/06-dashboard-architecture.md lists Users among the CMS's
// managed resources). RLS (profile_update_admin, added in migration
// 20260704155058) is the row-access gate: an admin/super_admin may update
// another tenant member's row, nobody may touch another tenant's rows. This
// layer adds the app-level rule the trigger can't express as cleanly: an
// actor may never change their OWN role through this path, even if they are
// an admin — see identity.prevent_self_role_escalation's header comment for
// why that's enforced at the trigger level too (defense in depth).

import type { QueryExecutor } from "./query_executor.ts";
import { AppError } from "./errors.ts";

export interface UserProfile {
  id: string;
  email: string | null;
  displayName: string | null;
  appRole: string;
  createdAt: string;
}

const VALID_APP_ROLES = ["buyer", "seller", "catalog_editor", "moderator", "finance", "support", "admin", "super_admin"];

function mapProfileRow(r: { id: string; email: string | null; display_name: string | null; app_role: string; created_at: string }): UserProfile {
  return { id: r.id, email: r.email, displayName: r.display_name, appRole: r.app_role, createdAt: r.created_at };
}

export async function fetchProfiles(db: QueryExecutor): Promise<UserProfile[]> {
  const result = await db.queryObject<Parameters<typeof mapProfileRow>[0]>(
    `select p.id, u.email, p.display_name, p.app_role, p.created_at
     from identity.profile p
     join auth.users u on u.id = p.id
     order by p.created_at desc`,
  );
  return result.rows.map(mapProfileRow);
}

export async function fetchProfileById(db: QueryExecutor, id: string): Promise<UserProfile> {
  const result = await db.queryObject<Parameters<typeof mapProfileRow>[0]>(
    `select p.id, u.email, p.display_name, p.app_role, p.created_at
     from identity.profile p
     join auth.users u on u.id = p.id
     where p.id = $1`,
    [id],
  );
  if (result.rows.length === 0) {
    throw new AppError(404, "not_found", `User ${id} not found.`);
  }
  return mapProfileRow(result.rows[0]);
}

export async function updateUserRole(
  db: QueryExecutor,
  actorId: string,
  targetUserId: string,
  newRole: string,
): Promise<UserProfile> {
  if (!VALID_APP_ROLES.includes(newRole)) {
    throw new AppError(422, "validation_failed", `role must be one of ${VALID_APP_ROLES.join(", ")}`, [
      { field: "appRole", code: "invalid_enum", message: `must be one of ${VALID_APP_ROLES.join(", ")}` },
    ]);
  }
  if (actorId === targetUserId) {
    throw new AppError(403, "forbidden", "You cannot change your own role.");
  }

  const result = await db.queryObject<{ id: string }>(
    `update identity.profile set app_role = $1, updated_at = now() where id = $2 returning id`,
    [newRole, targetUserId],
  );
  if (result.rows.length === 0) {
    // RLS silently filtered the row out (not an admin, or not the same
    // tenant) — see backend/tests/README.md's note on UPDATE vs INSERT RLS.
    throw new AppError(404, "not_found", `User ${targetUserId} not found or not editable by you.`);
  }
  return await fetchProfileById(db, targetUserId);
}
