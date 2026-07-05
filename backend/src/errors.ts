// Portable domain error taxonomy — no HTTP/Deno-specific concerns here (those
// live in supabase/functions/_shared/errors.ts, which formats these as the
// contract's ErrorEnvelope). Mirrors docs/planning/02-ios-architecture.md §8's
// DomainError taxonomy on the client side: one shared shape, mapped to
// platform-appropriate presentation at the edge.

export interface FieldError {
  field: string;
  code: string;
  message: string;
}

export class AppError extends Error {
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
