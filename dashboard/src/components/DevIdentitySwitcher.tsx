"use client";

import { useState } from "react";
import { useAuth } from "./AuthProvider";
import { DEV_IDENTITIES } from "@/lib/session";

/**
 * LOCAL DEV ONLY. Stands in for a real login screen — real authentication
 * (email/OTP/Apple/Google via wrapped Supabase Auth, ADR-0007) is unimplemented
 * Phase 1 roadmap work; this switches between the fixed identities seeded by
 * backend/supabase/seed/02_dev_test_users.sql via POST /v1/dev-auth, itself a
 * dev-only stand-in for GoTrue (no Docker in this environment — see
 * backend/README.md). Remove this component when real auth lands.
 */
export function DevIdentitySwitcher() {
  const { session, loginAs, logout } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleChange(e: React.ChangeEvent<HTMLSelectElement>) {
    const sub = e.target.value;
    if (!sub) {
      logout();
      return;
    }
    const identity = DEV_IDENTITIES.find((i) => i.sub === sub);
    if (!identity) return;
    setBusy(true);
    setError(null);
    try {
      await loginAs(identity.sub, identity.appRole, identity.displayName);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex items-center gap-2 text-sm">
      <span className="rounded bg-amber-100 px-2 py-0.5 text-amber-800 text-xs font-medium">DEV LOGIN</span>
      <select
        className="rounded border border-slate-300 bg-white px-2 py-1 text-slate-900"
        value={session?.sub ?? ""}
        onChange={handleChange}
        disabled={busy}
      >
        <option value="">Signed out (anon)</option>
        {DEV_IDENTITIES.map((i) => (
          <option key={i.sub} value={i.sub}>
            {i.displayName} ({i.appRole})
          </option>
        ))}
      </select>
      {error && <span className="text-red-600">{error}</span>}
    </div>
  );
}
