"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";
import { clearSession, DEFAULT_TENANT_ID, loadSession, saveSession, type Session } from "@/lib/session";
import { devLogin } from "@/lib/api";

interface AuthContextValue {
  session: Session | null;
  loginAs: (sub: string, appRole: string, displayName: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);

  useEffect(() => {
    // This *must* run in an effect, not a lazy useState initializer: the
    // server render has no window (loadSession() returns null there), so the
    // first client render has to match that (null) for hydration to succeed.
    // Reading localStorage in an initializer instead caused a real hydration
    // mismatch whenever a session already existed — verified in the browser,
    // reverted after react-hooks/set-state-in-effect's suggestion broke it.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setSession(loadSession());
  }, []);

  const loginAs = useCallback(async (sub: string, appRole: string, displayName: string) => {
    const accessToken = await devLogin({ sub, role: "authenticated", tenantId: DEFAULT_TENANT_ID, appRole });
    const next: Session = { accessToken, sub, role: "authenticated", tenantId: DEFAULT_TENANT_ID, appRole, displayName };
    saveSession(next);
    setSession(next);
  }, []);

  const logout = useCallback(() => {
    clearSession();
    setSession(null);
  }, []);

  return <AuthContext.Provider value={{ session, loginAs, logout }}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
