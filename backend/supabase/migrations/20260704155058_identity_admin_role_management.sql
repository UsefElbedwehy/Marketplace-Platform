-- Closes a real gap left by 20260704061000_identity_schema.sql: the original
-- prevent_self_role_escalation trigger blocked app_role changes from ANY
-- non-service_role actor — which meant not even an admin could promote
-- another user through the app, only service_role could. That's wrong: the
-- goal was to block *self*-escalation, not all app-level role management.
-- This migration (forward-only — the original stays as history) adds the
-- missing RLS policy and narrows the trigger to the intended rule: nobody
-- but service_role may ever change their OWN app_role/tenant_id; an
-- admin/super_admin MAY change ANOTHER tenant member's app_role (but still
-- not tenant_id — reassigning tenants stays service_role-only, it's rarer
-- and more sensitive than a role change).

-- RLS previously only had profile_update_own (id = auth.uid()), so an admin
-- attempting to UPDATE someone else's row was blocked at the RLS layer
-- before ever reaching the trigger. This policy adds that access; the
-- trigger below is what still stops it from being used to reassign tenants
-- or to self-escalate.
create policy profile_update_admin on identity.profile
  for update
  using (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'))
  with check (tenant_id = platform.current_tenant_id() and platform.current_app_role() in ('admin', 'super_admin'));

create or replace function identity.prevent_self_role_escalation() returns trigger
language plpgsql
as $$
begin
  if auth.role() = 'service_role' then
    return new;
  end if;

  if new.app_role is distinct from old.app_role then
    if new.id = auth.uid() then
      raise exception 'you cannot change your own app_role';
    end if;
    if platform.current_app_role() not in ('admin', 'super_admin') then
      raise exception 'app_role can only be changed by an admin/super_admin (for other users) or service_role';
    end if;
  end if;

  if new.tenant_id is distinct from old.tenant_id then
    raise exception 'tenant_id can only be changed by service_role';
  end if;

  return new;
end;
$$;
