// JWT verification/minting.
//
// LOCAL DEV LIMITATION: there is no GoTrue/Docker available in this
// environment (see backend/README.md), so tokens here are minted and
// verified with a local HMAC secret via v1-dev-auth — NOT real Supabase Auth.
// A real deployment verifies Supabase's actual (asymmetric, GoTrue-issued)
// JWTs instead; only this module's verifyToken/mintDevToken would change,
// nothing downstream (claims shape is identical either way).

import { create, getNumericDate, verify } from "djwt";
import { AppError } from "./errors.ts";

const DEV_SECRET_TEXT = Deno.env.get("LOCAL_DEV_JWT_SECRET") ?? "local-dev-only-secret-do-not-use-in-production";

const PG_ROLES = ["anon", "authenticated", "service_role"] as const;
type PgRole = (typeof PG_ROLES)[number];

export interface Claims {
  sub: string;
  role: PgRole;
  tenant_id?: string;
  app_role?: string;
  exp?: number;
}

let cachedKey: CryptoKey | null = null;
async function getKey(): Promise<CryptoKey> {
  if (cachedKey) return cachedKey;
  cachedKey = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(DEV_SECRET_TEXT),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
  return cachedKey;
}

export async function mintDevToken(claims: Omit<Claims, "exp">): Promise<string> {
  const key = await getKey();
  return await create({ alg: "HS256", typ: "JWT" }, { ...claims, exp: getNumericDate(60 * 60 * 24) }, key);
}

// Runtime-validates the decoded payload before it's ever trusted — in
// particular `role` ends up interpolated into a `SET LOCAL ROLE` statement in
// db.ts (SET does not support bind parameters for identifiers), so this is
// the one place that must not just trust the JWT's shape.
function assertValidClaims(payload: unknown): Claims {
  if (typeof payload !== "object" || payload === null) {
    throw new AppError(401, "unauthorized", "Malformed token payload.");
  }
  const p = payload as Record<string, unknown>;
  if (typeof p.sub !== "string" || !PG_ROLES.includes(p.role as PgRole)) {
    throw new AppError(401, "unauthorized", "Token is missing required claims.");
  }
  return {
    sub: p.sub,
    role: p.role as PgRole,
    tenant_id: typeof p.tenant_id === "string" ? p.tenant_id : undefined,
    app_role: typeof p.app_role === "string" ? p.app_role : undefined,
  };
}

export async function verifyToken(token: string): Promise<Claims> {
  const key = await getKey();
  try {
    const payload = await verify(token, key);
    return assertValidClaims(payload);
  } catch (e) {
    if (e instanceof AppError) throw e;
    throw new AppError(401, "unauthorized", "Invalid or expired token.");
  }
}

/** Resolves claims from the Authorization header, defaulting to an anonymous session if absent. */
export async function resolveClaims(req: Request): Promise<Claims> {
  const authHeader = req.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return { sub: "00000000-0000-0000-0000-000000000000", role: "anon" };
  }
  return await verifyToken(authHeader.slice("Bearer ".length));
}
