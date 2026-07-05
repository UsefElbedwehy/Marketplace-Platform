// LOCAL DEV ONLY. Mints a JWT for testing without real GoTrue/Docker — NOT
// part of the production API contract (absent from contract/openapi) and
// must never be deployed to a real Supabase project. Real authentication
// (email/OTP/Apple/Google via wrapped Supabase Auth, per ADR-0007) is Phase 1
// roadmap work not yet implemented; this exists solely to unblock exercising
// authenticated/admin RLS paths and the dashboard against a real local
// Postgres in the meantime. See backend/README.md.

import { mintDevToken } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";

interface DevLoginBody {
  sub: string;
  role: "anon" | "authenticated" | "service_role";
  tenant_id?: string;
  app_role?: string;
}

export async function handleDevAuthRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  try {
    if (req.method !== "POST") {
      throw new AppError(405, "method_not_allowed", "Only POST is supported.");
    }
    const body = (await req.json()) as DevLoginBody;
    if (!body.sub || !body.role) {
      throw new AppError(422, "validation_failed", "sub and role are required.", [
        { field: "sub", code: "required", message: "sub is required" },
      ]);
    }
    const token = await mintDevToken(body);
    return withCors(jsonResponse(200, { data: { accessToken: token } }));
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleDevAuthRequest);
}
