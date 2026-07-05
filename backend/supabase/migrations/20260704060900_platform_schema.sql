-- platform schema: tenant + audit_log.
--
-- Default deployment mode is single-tenant-per-deployment (one Supabase project
-- per client), but every domain table still carries tenant_id and is
-- RLS-scoped by it, so a shared multi-tenant mode needs no structural
-- migration later. See docs/planning/04-database-architecture.md §3 and
-- ADR-0011.

create schema if not exists platform;

create table platform.tenant (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  display_name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

comment on table platform.tenant is
  'One row per client deployment. In single-tenant mode there is exactly one active row; a shared multi-tenant deployment would have many.';

-- Our own helper (not a real Supabase auth.* function, hence it lives here, not
-- in `auth`) reading the tenant_id custom claim that our JWT issuance embeds.
-- See identity.custom_access_token_hook (next migration) for how tenant_id and
-- app_role get onto the token.
create or replace function platform.current_tenant_id() returns uuid
  language sql stable
  as $$
    select nullif(auth.jwt() ->> 'tenant_id', '')::uuid
  $$;

create table platform.audit_log (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references platform.tenant(id),
  actor_id uuid references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  request_id text,
  created_at timestamptz not null default now()
);

comment on table platform.audit_log is
  'Immutable log of every admin/schema/config/moderation mutation: who changed the marketplace structure, when. Insert-only — see policies below.';

create index audit_log_tenant_created_idx on platform.audit_log (tenant_id, created_at desc);

-- BYPASSRLS (service_role) skips row-security policies, not object-level
-- privileges — every role still needs an explicit GRANT to touch these
-- tables at all. RLS policies below are what actually restrict rows.
grant usage on schema platform to anon, authenticated, service_role;
grant select on platform.tenant to anon, authenticated, service_role;
grant insert, update, delete on platform.tenant to service_role;
grant select on platform.audit_log to authenticated, service_role;
grant insert on platform.audit_log to service_role;

alter table platform.tenant enable row level security;
alter table platform.audit_log enable row level security;

-- tenant: readable by anyone scoped to it (dashboard/app bootstrap needs the
-- display name etc.); provisioning a tenant is an operational action, not
-- exposed to end users or admins through the app, so writes are service_role-only.
create policy tenant_select on platform.tenant
  for select
  using (id = platform.current_tenant_id() or auth.role() = 'service_role');

create policy tenant_service_write on platform.tenant
  for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');

-- audit_log: admins of the tenant can read; nobody updates or deletes rows
-- (no UPDATE/DELETE policy is defined, so those are denied by default even to
-- `authenticated` — only service_role, which bypasses RLS entirely, can insert).
create policy audit_log_select_admin on platform.audit_log
  for select
  using (
    tenant_id = platform.current_tenant_id()
    and coalesce(auth.jwt() ->> 'app_role', '') in ('admin', 'super_admin', 'catalog_editor', 'moderator', 'finance')
  );
