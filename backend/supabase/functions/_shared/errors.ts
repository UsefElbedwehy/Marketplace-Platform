// HTTP formatting for the portable AppError taxonomy (backend/src/errors.ts) —
// this file is the Edge-Function-runtime-specific half; the error shape
// itself is portable. See contract/openapi/v1/openapi.yaml#/components/schemas/ErrorEnvelope.

import { AppError } from "../../../src/errors.ts";

export { AppError };
export type { FieldError } from "../../../src/errors.ts";

export function jsonResponse(status: number, body: unknown, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...headers },
  });
}

export function errorResponse(err: unknown, requestId: string): Response {
  if (err instanceof AppError) {
    return jsonResponse(err.status, {
      error: {
        code: err.code,
        message: err.message,
        requestId,
        ...(err.fields ? { fields: err.fields } : {}),
      },
    });
  }
  console.error("unhandled error:", err);
  return jsonResponse(500, {
    error: { code: "internal_error", message: "An unexpected error occurred.", requestId },
  });
}
