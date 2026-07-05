// Local-dev session storage. Mirrors what a real session (Supabase Auth,
// once Phase 1's actual GoTrue-backed flows land) would provide — an access
// token plus the identity claims needed to render "who am I" — but sourced
// from POST /v1/dev-auth (see backend/supabase/functions/v1-dev-auth), the
// local-only token minter this environment uses in place of Docker/GoTrue.

export interface Session {
  accessToken: string;
  sub: string;
  role: "anon" | "authenticated" | "service_role";
  tenantId: string;
  appRole: string;
  displayName: string;
}

const STORAGE_KEY = "marketplace-platform.dashboard.session";

export function loadSession(): Session | null {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(STORAGE_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as Session;
  } catch {
    return null;
  }
}

export function saveSession(session: Session): void {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
}

export function clearSession(): void {
  window.localStorage.removeItem(STORAGE_KEY);
}

// Fixed dev identities seeded by backend/supabase/seed/02_dev_test_users.sql —
// one per app_role, all in the "default" tenant, so the dashboard has
// something real to authenticate as without a signup flow.
export const DEV_IDENTITIES: Array<{ sub: string; appRole: string; displayName: string }> = [
  { sub: "90000001-0000-0000-0000-000000000004", appRole: "admin", displayName: "Dev Admin" },
  { sub: "90000001-0000-0000-0000-000000000003", appRole: "catalog_editor", displayName: "Dev Catalog Editor" },
  { sub: "90000001-0000-0000-0000-000000000005", appRole: "moderator", displayName: "Dev Moderator" },
  { sub: "90000001-0000-0000-0000-000000000002", appRole: "seller", displayName: "Dev Seller" },
  { sub: "90000001-0000-0000-0000-000000000001", appRole: "buyer", displayName: "Dev Buyer" },
];

export const DEFAULT_TENANT_ID = "00000000-0000-0000-0000-000000000001";
