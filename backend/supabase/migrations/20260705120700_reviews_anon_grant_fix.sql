-- Fixes a real bug caught by the RLS test suite (060_social_tests.sql): an
-- anonymous caller reading a seller's reviews got "permission denied for
-- table review" — review_select_public's RLS policy already permits anon
-- (same class of gap as the seller-profile anon grant fix, 20260705120500):
-- the original schema migration only ever granted SELECT on social.review
-- to `authenticated`, never `anon`, even though reviews are meant to be
-- public read (mirroring "published listings are public").

grant select on social.review to anon;
