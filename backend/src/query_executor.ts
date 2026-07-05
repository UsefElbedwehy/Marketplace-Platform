// The only thing backend/src (portable domain logic — services/repositories)
// depends on to talk to data. `supabase/functions/_shared/db.ts`'s PoolClient
// satisfies this structurally; a fake satisfying it is what unit tests use
// (docs/planning/09-cross-cutting.md — "Unit: domain services ... with mocks").
// This is the seam ADR-0002 describes: swap what implements QueryExecutor,
// not the services that consume it.

export interface QueryResult<T> {
  rows: T[];
}

export interface QueryExecutor {
  queryObject<T>(sql: string, args?: unknown[]): Promise<QueryResult<T>>;
}
