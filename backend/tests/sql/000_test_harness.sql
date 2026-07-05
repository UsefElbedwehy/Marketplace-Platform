-- Minimal, dependency-free test harness (no pgTAP install needed). A test
-- schema + a handful of assert_* helpers that record results into
-- test.results; 999_report.sql raises an exception (non-zero exit for the
-- runner script) if anything failed.

create schema if not exists test;

create table test.results (
  id bigint generated always as identity primary key,
  name text not null,
  passed boolean not null,
  detail text
);

-- SECURITY DEFINER: the assert_* helpers below are called while the session
-- is impersonating anon/authenticated/service_role (via test.act_as*) so the
-- RLS-sensitive dynamic SQL they execute runs under the right role — but
-- recording the result must always succeed regardless of that role's own
-- privileges on test.results, so only this one function runs as its owner.
create or replace function test.record(p_name text, p_passed boolean, p_detail text default null) returns void
language sql security definer as $$
  insert into test.results (name, passed, detail) values (p_name, p_passed, p_detail);
$$;

create or replace function test.assert_true(p_name text, p_condition boolean, p_detail text default null) returns void
language plpgsql as $$
begin
  perform test.record(p_name, coalesce(p_condition, false), p_detail);
end;
$$;

create or replace function test.assert_count(p_name text, p_expected bigint, p_actual bigint) returns void
language plpgsql as $$
begin
  perform test.record(p_name, p_expected = p_actual, format('expected %s, got %s', p_expected, p_actual));
end;
$$;

-- Executes p_sql and expects it to raise an exception (e.g. an RLS or trigger rejection).
create or replace function test.assert_raises(p_name text, p_sql text) returns void
language plpgsql as $$
begin
  execute p_sql;
  perform test.record(p_name, false, 'expected an exception but none was raised');
exception when others then
  perform test.record(p_name, true, sqlerrm);
end;
$$;

-- Executes p_sql and expects it NOT to raise.
create or replace function test.assert_succeeds(p_name text, p_sql text) returns void
language plpgsql as $$
begin
  execute p_sql;
  perform test.record(p_name, true);
exception when others then
  perform test.record(p_name, false, sqlerrm);
end;
$$;

-- Session-simulation helpers: switch the connection's Postgres role and
-- simulated JWT claims, mirroring what PostgREST would set per-request from
-- a real decoded token (see migration 20260704060802's auth.uid()/auth.jwt()).

create or replace function test.act_as(p_sub uuid, p_tenant uuid, p_app_role text) returns void
language plpgsql as $$
begin
  execute 'set role authenticated';
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', p_sub, 'role', 'authenticated', 'tenant_id', p_tenant, 'app_role', p_app_role)::text,
    false
  );
end;
$$;

create or replace function test.act_as_anon() returns void
language plpgsql as $$
begin
  execute 'reset role';
  execute 'set role anon';
  perform set_config('request.jwt.claims', '', false);
end;
$$;

create or replace function test.act_as_service() returns void
language plpgsql as $$
begin
  execute 'reset role';
  execute 'set role service_role';
  -- auth.role() reads request.jwt.claims, not the actual Postgres role — a
  -- stale claims blob from a prior test.act_as() would leave auth.role()
  -- reporting 'authenticated' even though the session role is now
  -- service_role. The real request path (withRequestContext) always sets
  -- both together; this mirrors that so triggers keyed on auth.role() see a
  -- consistent picture.
  perform set_config('request.jwt.claims', jsonb_build_object('role', 'service_role')::text, false);
end;
$$;

-- Every simulated role needs USAGE + EXECUTE to even call these helpers —
-- they don't inherit access from whichever role created the schema. SELECT
-- on test.results is separate from test.record's SECURITY DEFINER write path
-- and is what 999_report.sql needs to read the final tally.
grant usage on schema test to anon, authenticated, service_role;
grant execute on all functions in schema test to anon, authenticated, service_role;
grant select on test.results to anon, authenticated, service_role;
