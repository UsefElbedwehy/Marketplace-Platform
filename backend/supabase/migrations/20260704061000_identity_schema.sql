-- identity schema: profile extension over auth.users + role/tenant assignment.
--
-- Authorization model (docs/planning/08-api-auth.md Part B, ADR-0007): roles
-- and the tenant claim live in the JWT so RLS can check them cheaply
-- (auth.jwt()->>'app_role', platform.current_tenant_id()) without a join on
-- every row. identity.profile is the durable source those claims are minted
-- from — identity.custom_access_token_hook is what a real Supabase project
-- wires up (via config.toml's [auth.hook.custom_access_token]) to embed them
-- at token-issuance time. That hook cannot be exercised locally without
-- Docker/GoTrue; it is unit-tested directly as a plain SQL function below
-- (see backend/tests) since its contract (input/output event shape) doesn't
-- require a running Auth server to verify.

create schema if not exists identity;

create table identity.profile (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid not null references platform.tenant(id),
  display_name text,
  app_role text not null default 'buyer'
    check (app_role in ('buyer', 'seller', 'catalog_editor', 'moderator', 'finance', 'support', 'admin', 'super_admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table identity.profile is
  'Durable role/tenant assignment per user. Embedded into the JWT at issuance by identity.custom_access_token_hook so RLS reads claims, not this table, on the hot path.';

create index profile_tenant_idx on identity.profile (tenant_id);

-- Our own read helper for app_role, mirroring platform.current_tenant_id()'s
-- pattern: read from the JWT claim, default to the least-privileged role.
create or replace function platform.current_app_role() returns text
  language sql stable
  as $$
    select coalesce(auth.jwt() ->> 'app_role', 'buyer')
  $$;

-- Supabase Auth Hooks contract: receives {user_id, claims, authentication_method}
-- and must return an event whose `claims` key carries the (possibly modified)
-- claims map. See https://supabase.com/docs/guides/auth/auth-hooks for the
-- real contract this mirrors.
create or replace function identity.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
stable
as $$
declare
  claims jsonb;
  profile_row identity.profile;
begin
  select * into profile_row from identity.profile where id = (event ->> 'user_id')::uuid;
  claims := coalesce(event -> 'claims', '{}'::jsonb);

  if profile_row.id is not null then
    claims := jsonb_set(claims, '{app_role}', to_jsonb(profile_row.app_role));
    claims := jsonb_set(claims, '{tenant_id}', to_jsonb(profile_row.tenant_id::text));
  else
    claims := jsonb_set(claims, '{app_role}', to_jsonb('buyer'::text));
  end if;

  return jsonb_set(event, '{claims}', claims);
end;
$$;

grant usage on schema identity to anon, authenticated, service_role;
grant select, update on identity.profile to authenticated;
grant select, insert, update, delete on identity.profile to service_role;

alter table identity.profile enable row level security;

-- Users read/update their own profile; admins of the same tenant can read
-- (for moderation/role-management UI) but role changes are service_role-only
-- (an admin cannot silently self-promote by writing their own row).
create policy profile_select_own_or_admin on identity.profile
  for select
  using (
    id = auth.uid()
    or (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'))
  );

-- RLS restricts which ROWS a policy allows, not which COLUMNS within an
-- allowed row — `using/with check (id = auth.uid())` alone would let a user
-- update their OWN row's app_role/tenant_id, a privilege-escalation path.
-- The trigger below closes that: only service_role may change those two
-- columns; everything else (display_name, ...) a user can still self-edit.
create policy profile_update_own on identity.profile
  for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy profile_insert_service on identity.profile
  for insert
  with check (auth.role() = 'service_role');

create or replace function identity.prevent_self_role_escalation() returns trigger
language plpgsql
as $$
begin
  if auth.role() <> 'service_role' then
    if new.app_role is distinct from old.app_role then
      raise exception 'app_role can only be changed by service_role';
    end if;
    if new.tenant_id is distinct from old.tenant_id then
      raise exception 'tenant_id can only be changed by service_role';
    end if;
  end if;
  return new;
end;
$$;

create trigger profile_prevent_self_role_escalation
  before update on identity.profile
  for each row execute function identity.prevent_self_role_escalation();
