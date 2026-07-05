-- config schema: versioned runtime config/theme bundles, per tenant.
--
-- Each row is a full document (already merged: default <- client <- env, per
-- contract/README.md's merge model) as validated JSON — the backend stores
-- the *effective* document, not the overlay fragments. `is_active` marks the
-- currently-served version; publishing a change inserts a new version and
-- flips is_active, so history and rollback come for free. See
-- docs/planning/07-configuration-whitelabel-theme.md and ADR-0004.

create schema if not exists config;

create table config.bundle (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references platform.tenant(id),
  version int not null,
  document jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, version)
);

comment on table config.bundle is
  'Versioned runtime config documents (contract/schema/config.schema.json shape). Exactly one row per tenant has is_active = true — see bundle_one_active_per_tenant.';

create table config.theme (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references platform.tenant(id),
  version int not null,
  document jsonb not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (tenant_id, version)
);

comment on table config.theme is
  'Versioned theme token documents (contract/schema/theme.schema.json shape). Exactly one row per tenant has is_active = true.';

create unique index bundle_one_active_per_tenant on config.bundle (tenant_id) where is_active;
create unique index theme_one_active_per_tenant on config.theme (tenant_id) where is_active;

grant usage on schema config to anon, authenticated, service_role;
grant select on config.bundle, config.theme to anon, authenticated;
-- Admin/super_admin writes go through the user's own authenticated session
-- (Config/Theme Studio), not just service_role — the RLS policies below are
-- what actually restrict this to the right tenant + role; without this
-- GRANT, even an admin would be blocked at the object-privilege level before
-- RLS is ever evaluated (the same gap caught on catalog.* — see that migration).
grant insert, update, delete on config.bundle, config.theme to authenticated;
grant select, insert, update, delete on config.bundle, config.theme to service_role;

alter table config.bundle enable row level security;
alter table config.theme enable row level security;

-- Guest-first (ADR-0007): config/theme reads are public. In single-tenant mode
-- there's one active row per table anyway; an anonymous session (no tenant_id
-- claim) sees any active row, an authenticated session sees its own tenant's.
create policy bundle_select_public on config.bundle
  for select
  using (is_active and (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id()));

create policy theme_select_public on config.theme
  for select
  using (is_active and (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id()));

-- Publishing (insert/update/delete) is an admin or service_role action, scoped
-- to the admin's own tenant — the dashboard's Config/Theme Studio writes
-- through here (docs/planning/06-dashboard-architecture.md §4).
create policy bundle_write_admin on config.bundle
  for all
  using (
    auth.role() = 'service_role'
    or (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'))
  )
  with check (
    auth.role() = 'service_role'
    or (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'))
  );

create policy theme_write_admin on config.theme
  for all
  using (
    auth.role() = 'service_role'
    or (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'))
  )
  with check (
    auth.role() = 'service_role'
    or (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'))
  );
