"use client";

import { useState } from "react";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/components/AuthProvider";
import type { UserProfile } from "@/lib/contract-types";

// Mirrors backend/src/user_service.ts's VALID_APP_ROLES — kept in sync by
// hand since this is a fixed enum in the OpenAPI contract, not fetched data.
const APP_ROLES = ["buyer", "seller", "catalog_editor", "moderator", "finance", "support", "admin", "super_admin"];

export default function UsersPage() {
  const { session } = useAuth();
  const isAdmin = session?.appRole === "admin" || session?.appRole === "super_admin";

  const { data: users, loading, error, reload } = useApi<UserProfile[]>(isAdmin ? "/v1/users" : null, [session?.sub]);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  async function changeRole(userId: string, appRole: string) {
    setBusyId(userId);
    setActionError(null);
    try {
      await api.patch(`/v1/users/${userId}`, { appRole });
      reload();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : "Failed to update role");
    } finally {
      setBusyId(null);
    }
  }

  if (!session) {
    return (
      <p className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
        Sign in (any dev identity) to view this page.
      </p>
    );
  }

  if (!isAdmin) {
    return (
      <p className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
        Only an admin can manage users.
      </p>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-lg font-semibold">Users</h1>
        <p className="mt-1 text-sm text-slate-600">Manage tenant members&rsquo; roles. You cannot change your own role.</p>
      </div>

      {(error || actionError) && (
        <p className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {actionError ?? error?.message}
        </p>
      )}

      {loading && <p className="text-sm text-slate-500">Loading…</p>}

      {users && (
        <div className="overflow-hidden rounded-lg border border-slate-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
              <tr>
                <th className="px-4 py-2 font-medium">Name</th>
                <th className="px-4 py-2 font-medium">Email</th>
                <th className="px-4 py-2 font-medium">Role</th>
                <th className="px-4 py-2 font-medium">Joined</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {users.map((u) => {
                const isSelf = u.id === session.sub;
                const busy = busyId === u.id;
                return (
                  <tr key={u.id}>
                    <td className="px-4 py-2 font-medium text-slate-900">
                      {u.displayName ?? "—"}
                      {isSelf && <span className="ml-2 rounded-full bg-slate-100 px-1.5 py-0.5 text-xs font-normal text-slate-500">you</span>}
                    </td>
                    <td className="px-4 py-2 text-slate-600">{u.email ?? "—"}</td>
                    <td className="px-4 py-2">
                      <select
                        className="rounded border border-slate-300 bg-white px-2 py-1 text-slate-900 disabled:opacity-50"
                        value={u.appRole}
                        disabled={isSelf || busy}
                        title={isSelf ? "You cannot change your own role." : undefined}
                        onChange={(e) => changeRole(u.id, e.target.value)}
                      >
                        {APP_ROLES.map((role) => (
                          <option key={role} value={role}>
                            {role}
                          </option>
                        ))}
                      </select>
                    </td>
                    <td className="px-4 py-2 text-slate-500">{u.createdAt ? new Date(u.createdAt).toLocaleDateString() : "—"}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
