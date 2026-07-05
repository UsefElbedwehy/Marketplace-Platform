-- Fixes a real bug caught by the RLS test suite (060_social_tests.sql's
-- cleanup step): service_role could not DELETE from platform.outbox. Every
-- other Phase 6 table's grant explicitly gives service_role the full
-- select/insert/update/delete set (see the original migration's
-- `grant select, insert, update, delete on social.conversation, ... to
-- service_role`); platform.outbox's grant line was inconsistent with that
-- pattern and only ever granted select/insert/update, to both authenticated
-- and service_role together, never delete to either.

grant delete on platform.outbox to service_role;
