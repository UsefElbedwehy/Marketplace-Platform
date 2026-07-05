-- Fixes a real bug caught via live curl verification: favorites_service.ts's
-- addFavorite() uses `insert ... on conflict (user_id, listing_id) do update
-- ...` to make re-favoriting idempotent and always return a row. Postgres
-- requires UPDATE privilege on the target table for the DO UPDATE branch of
-- an upsert even when no conflict actually occurs (it's part of planning the
-- statement, not just executing it) — the original migration only granted
-- select/insert/delete on social.favorite to authenticated, so every
-- PUT /v1/favorites/{listingId} failed with "permission denied for table
-- favorite" (a raw GRANT error, not an RLS policy violation — confirmed by
-- reproducing the same INSERT directly under an impersonated session).

grant update on social.favorite to authenticated;
