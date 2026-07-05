// Typed client over the REST contract (docs/planning/06-dashboard-architecture.md
// §8 — the dashboard consumes the *same* contract the apps do, never a
// private API, so the Schema Builder's preview is guaranteed faithful).

import { loadSession } from "./session";

const BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

export interface FieldError {
  field: string;
  code: string;
  message: string;
}

export class ApiError extends Error {
  status: number;
  code: string;
  fields?: FieldError[];

  constructor(status: number, code: string, message: string, fields?: FieldError[]) {
    super(message);
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const session = loadSession();
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (session) headers["authorization"] = `Bearer ${session.accessToken}`;

  const res = await fetch(`${BASE_URL}${path}`, { ...init, headers: { ...headers, ...(init?.headers as Record<string, string>) } });

  if (res.status === 204 || res.status === 304) {
    return undefined as T;
  }

  const body = await res.json().catch(() => null);

  if (!res.ok) {
    const err = body?.error;
    throw new ApiError(res.status, err?.code ?? "unknown_error", err?.message ?? `Request failed (${res.status})`, err?.fields);
  }

  return (body?.data ?? body) as T;
}

export const api = {
  get: <T>(path: string) => request<T>(path, { method: "GET" }),
  post: <T>(path: string, body: unknown) => request<T>(path, { method: "POST", body: JSON.stringify(body) }),
  patch: <T>(path: string, body: unknown) => request<T>(path, { method: "PATCH", body: JSON.stringify(body) }),
};

export async function devLogin(input: { sub: string; role: "authenticated"; tenantId: string; appRole: string }) {
  const res = await fetch(`${BASE_URL}/v1/dev-auth`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ sub: input.sub, role: input.role, tenant_id: input.tenantId, app_role: input.appRole }),
  });
  const body = await res.json();
  if (!res.ok) throw new ApiError(res.status, body?.error?.code ?? "unknown_error", body?.error?.message ?? "Login failed");
  return body.data.accessToken as string;
}
