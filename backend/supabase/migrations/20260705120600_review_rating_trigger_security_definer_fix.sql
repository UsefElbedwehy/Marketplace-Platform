-- Fixes a real bug caught via live curl verification: after a buyer posted
-- a review, GET /v1/profiles/{sellerId} still showed ratingCount: 0. The
-- review insert itself succeeded, but social.bump_reviewee_rating() (its
-- AFTER INSERT trigger) runs as the INVOKING session by default — the
-- reviewer (a buyer), not the reviewee (the seller) whose row it's trying to
-- update. identity.profile's UPDATE policies (profile_update_own,
-- profile_update_admin) only ever permit a user to update their OWN row or
-- an admin to update a same-tenant row — a plain buyer has no RLS path to
-- update the seller's counters, so the trigger's UPDATE silently affected 0
-- rows (RLS filters UPDATE rows rather than raising, same distinction noted
-- throughout this codebase's other services).
--
-- Fix: SECURITY DEFINER, the standard Postgres pattern for "a trigger needs
-- to touch a table the invoking session doesn't have direct rights to" —
-- already used elsewhere in this codebase for the same reason (see
-- backend/tests/sql/000_test_harness.sql's test.record()). search_path is
-- pinned empty since the function body is fully schema-qualified already,
-- closing the standard search-path-hijack risk for SECURITY DEFINER
-- functions.

create or replace function social.bump_reviewee_rating() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update identity.profile set rating_count = rating_count + 1, rating_sum = rating_sum + new.rating
    where id = new.reviewee_id;
  return new;
end;
$$;
