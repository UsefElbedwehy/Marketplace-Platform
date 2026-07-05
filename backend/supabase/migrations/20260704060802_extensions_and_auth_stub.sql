-- Extensions + local auth-stub schema
--
-- A real Supabase project provides the `auth` schema (GoTrue), the
-- anon/authenticated/service_role roles, and auth.uid()/auth.role()/auth.jwt()
-- automatically. This repository has no Docker available in its current
-- development environment, so this migration creates a minimal, faithful stub
-- of that surface for local RLS testing against a plain Homebrew Postgres —
-- see backend/README.md for the exact limitation.
--
-- This migration is NOT applied against a real Supabase project (which
-- already provides the real versions of everything below) — it exists only
-- so `supabase/migrations/*` can be exercised end-to-end locally. Every
-- function here mirrors Supabase's real implementation so RLS policies
-- written against auth.uid()/auth.jwt() are portable, unmodified, to a real
-- deployment.

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end
$$;

create schema if not exists auth;

-- Minimal stand-in for GoTrue's auth.users. Real Supabase's auth.users has many
-- more columns; only what our RLS/local-dev seed needs is modeled here.
create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  phone text unique,
  created_at timestamptz not null default now()
);

-- Mirrors the real auth.uid()/auth.role()/auth.jwt() definitions: PostgREST
-- sets both a per-claim GUC (request.jwt.claim.sub) and the full claims blob
-- (request.jwt.claims) per request; local tests can set either.
create or replace function auth.uid() returns uuid
  language sql stable
  as $$
    select coalesce(
      nullif(current_setting('request.jwt.claim.sub', true), ''),
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
    )::uuid
  $$;

create or replace function auth.role() returns text
  language sql stable
  as $$
    select coalesce(
      nullif(current_setting('request.jwt.claim.role', true), ''),
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
    )::text
  $$;

create or replace function auth.jwt() returns jsonb
  language sql stable
  as $$
    select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb, '{}'::jsonb)
  $$;

grant usage on schema auth to anon, authenticated, service_role;
grant select on auth.users to anon, authenticated, service_role;
-- Real Supabase never lets even service_role write auth.users directly — user
-- creation goes through GoTrue's API. This grant exists ONLY so local test
-- fixtures can create users without a running Auth server (see backend/README.md).
grant insert, update on auth.users to service_role;
