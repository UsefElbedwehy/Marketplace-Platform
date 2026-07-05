-- catalog schema: the Dynamic Category & Attribute Engine ⭐
--
-- The dashboard-controlled source of truth for marketplace structure:
-- category tree -> attribute groups -> attributes -> options/dependencies.
-- Normalized definitions (this migration); the hybrid typed+JSONB value
-- store for actual listings is the next migration. See
-- docs/planning/05-dynamic-schema-engine.md and ADR-0003.

create schema if not exists catalog;

create table catalog.category (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references platform.tenant(id),
  parent_id uuid references catalog.category(id) on delete restrict,
  slug text not null,
  name_i18n jsonb not null,
  icon text,
  sort_order int not null default 0,
  is_leaf boolean not null default true,
  is_active boolean not null default true,
  -- Bumped whenever this category's composed schema (its own attribute
  -- groups/attributes/options/dependencies) changes — drives ETag caching on
  -- GET /v1/categories/{id}/schema. See the triggers at the end of this file.
  schema_version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table catalog.category is
  'Self-referencing category tree (unlimited nesting). A leaf category (is_leaf) is what a listing is actually posted under and carries the attribute schema.';

-- Slug uniqueness among siblings, not globally — a "condition" subcategory
-- slug can exist under both Vehicles and Electronics. NULL parent_id (top
-- level) needs its own partial index since Postgres treats NULLs as distinct
-- in a plain unique index.
create unique index category_top_level_slug_uidx on catalog.category (tenant_id, slug) where parent_id is null;
create unique index category_nested_slug_uidx on catalog.category (tenant_id, parent_id, slug) where parent_id is not null;
create index category_parent_idx on catalog.category (parent_id);
create index category_tenant_idx on catalog.category (tenant_id);

create table catalog.attribute_group (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references catalog.category(id) on delete cascade,
  name_i18n jsonb not null,
  sort_order int not null default 0,
  is_collapsible boolean not null default false
);

comment on table catalog.attribute_group is
  'Groups attributes for display within a leaf category''s form (e.g. "Details", "Condition & History").';

create index attribute_group_category_idx on catalog.attribute_group (category_id);

create table catalog.attribute (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references catalog.attribute_group(id) on delete cascade,
  key text not null,
  label_i18n jsonb not null,
  data_type text not null check (data_type in ('text', 'number', 'bool', 'date', 'option', 'option_multi', 'media', 'location')),
  input_type text not null check (input_type in ('textfield', 'textarea', 'stepper', 'slider', 'dropdown', 'chips', 'switch', 'datepicker', 'media', 'map')),
  validation jsonb not null default '{}'::jsonb,
  default_value jsonb,
  is_required boolean not null default false,
  is_filterable boolean not null default false,
  is_searchable boolean not null default false,
  is_active boolean not null default true,
  sort_order int not null default 0,
  unit text
);

comment on table catalog.attribute is
  'A single field in a category''s dynamic listing schema. data_type is the storage/semantic type (see listing.listing_attribute_value); input_type is how DynamicForms renders it — decoupled so one data_type can render multiple ways.';

-- Unique within its group (not the whole category) — see docs/planning/05-dynamic-schema-engine.md §3.
create unique index attribute_group_key_uidx on catalog.attribute (group_id, key);
create index attribute_group_idx on catalog.attribute (group_id);
create index attribute_filterable_idx on catalog.attribute (id) where is_filterable;

create table catalog.attribute_option (
  id uuid primary key default gen_random_uuid(),
  attribute_id uuid not null references catalog.attribute(id) on delete cascade,
  -- Self-reference models dependent option sets, e.g. Model options filtered
  -- by the selected Brand option (see attribute_dependency below).
  parent_option_id uuid references catalog.attribute_option(id) on delete cascade,
  value text not null,
  label_i18n jsonb not null,
  sort_order int not null default 0,
  is_active boolean not null default true
);

comment on table catalog.attribute_option is
  'Enum values for option/option_multi attributes. parent_option_id links a Model option to the Brand option it belongs to.';

create unique index attribute_option_value_uidx on catalog.attribute_option (attribute_id, value);
create index attribute_option_attribute_idx on catalog.attribute_option (attribute_id);
create index attribute_option_parent_idx on catalog.attribute_option (parent_option_id);

create table catalog.attribute_dependency (
  id uuid primary key default gen_random_uuid(),
  attribute_id uuid not null references catalog.attribute(id) on delete cascade,
  depends_on_id uuid not null references catalog.attribute(id) on delete cascade,
  rule text not null check (rule in ('visible_when', 'required_when', 'options_filtered_by')),
  condition jsonb not null default '{}'::jsonb,
  check (attribute_id <> depends_on_id)
);

comment on table catalog.attribute_dependency is
  'Field-to-field rules (e.g. "Model options_filtered_by Brand", "Furnished visible_when PropertyType = Apartment"). Composed into the schema contract client-side rendering reacts to.';

create unique index attribute_dependency_uidx on catalog.attribute_dependency (attribute_id, depends_on_id, rule);
create index attribute_dependency_attribute_idx on catalog.attribute_dependency (attribute_id);
create index attribute_dependency_depends_on_idx on catalog.attribute_dependency (depends_on_id);

-- === Grants ==================================================================

grant usage on schema catalog to anon, authenticated, service_role;
grant select on
  catalog.category, catalog.attribute_group, catalog.attribute,
  catalog.attribute_option, catalog.attribute_dependency
  to anon, authenticated;
grant select, insert, update, delete on
  catalog.category, catalog.attribute_group, catalog.attribute,
  catalog.attribute_option, catalog.attribute_dependency
  to service_role;
-- catalog_editor/admin write via RLS-checked authenticated grants (not just
-- service_role) so the dashboard can write through the user's own session.
grant insert, update, delete on
  catalog.category, catalog.attribute_group, catalog.attribute,
  catalog.attribute_option, catalog.attribute_dependency
  to authenticated;

-- === RLS ======================================================================

alter table catalog.category enable row level security;
alter table catalog.attribute_group enable row level security;
alter table catalog.attribute enable row level security;
alter table catalog.attribute_option enable row level security;
alter table catalog.attribute_dependency enable row level security;

create or replace function catalog.is_editor() returns boolean
  language sql stable
  as $$
    select auth.role() = 'service_role' or platform.current_app_role() in ('catalog_editor', 'admin', 'super_admin')
  $$;

-- category: public read of active rows (guest-first browsing); write is
-- catalog_editor/admin/super_admin (or service_role), scoped to the actor's
-- own tenant.
create policy category_select_public on catalog.category
  for select
  using (is_active and (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id()));

create policy category_write_editor on catalog.category
  for all
  using (catalog.is_editor() and (auth.role() = 'service_role' or tenant_id = platform.current_tenant_id()))
  with check (catalog.is_editor() and (auth.role() = 'service_role' or tenant_id = platform.current_tenant_id()));

-- attribute_group / attribute / attribute_option / attribute_dependency don't
-- carry tenant_id directly — they inherit tenant scoping through their parent
-- category via a join, since a category's row is already tenant-checked.
create policy attribute_group_select_public on catalog.attribute_group
  for select
  using (exists (
    select 1 from catalog.category c
    where c.id = attribute_group.category_id
      and c.is_active
      and (platform.current_tenant_id() is null or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_group_write_editor on catalog.attribute_group
  for all
  using (catalog.is_editor() and exists (
    select 1 from catalog.category c
    where c.id = attribute_group.category_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ))
  with check (catalog.is_editor() and exists (
    select 1 from catalog.category c
    where c.id = attribute_group.category_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_select_public on catalog.attribute
  for select
  using (exists (
    select 1 from catalog.attribute_group g
    join catalog.category c on c.id = g.category_id
    where g.id = attribute.group_id
      and c.is_active
      and (platform.current_tenant_id() is null or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_write_editor on catalog.attribute
  for all
  using (catalog.is_editor() and exists (
    select 1 from catalog.attribute_group g
    join catalog.category c on c.id = g.category_id
    where g.id = attribute.group_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ))
  with check (catalog.is_editor() and exists (
    select 1 from catalog.attribute_group g
    join catalog.category c on c.id = g.category_id
    where g.id = attribute.group_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_option_select_public on catalog.attribute_option
  for select
  using (exists (
    select 1 from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = attribute_option.attribute_id
      and c.is_active
      and (platform.current_tenant_id() is null or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_option_write_editor on catalog.attribute_option
  for all
  using (catalog.is_editor() and exists (
    select 1 from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = attribute_option.attribute_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ))
  with check (catalog.is_editor() and exists (
    select 1 from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = attribute_option.attribute_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_dependency_select_public on catalog.attribute_dependency
  for select
  using (exists (
    select 1 from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = attribute_dependency.attribute_id
      and c.is_active
      and (platform.current_tenant_id() is null or c.tenant_id = platform.current_tenant_id())
  ));

create policy attribute_dependency_write_editor on catalog.attribute_dependency
  for all
  using (catalog.is_editor() and exists (
    select 1 from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = attribute_dependency.attribute_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ))
  with check (catalog.is_editor() and exists (
    select 1 from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = attribute_dependency.attribute_id
      and (auth.role() = 'service_role' or c.tenant_id = platform.current_tenant_id())
  ));

-- === schema_version bump triggers ===========================================
-- Any change to a category's groups/attributes/options/dependencies bumps
-- that category's schema_version, which is what GET /v1/categories/{id}/schema
-- ETags against (docs/planning/05-dynamic-schema-engine.md §5, §8).

create or replace function catalog.bump_category_version(p_category_id uuid) returns void
  language sql
  as $$
    update catalog.category set schema_version = schema_version + 1, updated_at = now() where id = p_category_id;
  $$;

create or replace function catalog.bump_from_attribute_group() returns trigger
language plpgsql as $$
begin
  perform catalog.bump_category_version(coalesce(new.category_id, old.category_id));
  return coalesce(new, old);
end;
$$;

create trigger attribute_group_bump_version
  after insert or update or delete on catalog.attribute_group
  for each row execute function catalog.bump_from_attribute_group();

create or replace function catalog.bump_from_attribute() returns trigger
language plpgsql as $$
declare
  v_category_id uuid;
begin
  select category_id into v_category_id from catalog.attribute_group where id = coalesce(new.group_id, old.group_id);
  if v_category_id is not null then
    perform catalog.bump_category_version(v_category_id);
  end if;
  return coalesce(new, old);
end;
$$;

create trigger attribute_bump_version
  after insert or update or delete on catalog.attribute
  for each row execute function catalog.bump_from_attribute();

-- Shared by attribute_option and attribute_dependency — both tables have
-- their own attribute_id column pointing at catalog.attribute, so the same
-- lookup resolves the owning category for either.
create or replace function catalog.bump_from_attribute_ref() returns trigger
language plpgsql as $$
declare
  v_category_id uuid;
begin
  select c.id into v_category_id
    from catalog.attribute a
    join catalog.attribute_group g on g.id = a.group_id
    join catalog.category c on c.id = g.category_id
    where a.id = coalesce(new.attribute_id, old.attribute_id);
  if v_category_id is not null then
    perform catalog.bump_category_version(v_category_id);
  end if;
  return coalesce(new, old);
end;
$$;

create trigger attribute_option_bump_version
  after insert or update or delete on catalog.attribute_option
  for each row execute function catalog.bump_from_attribute_ref();

create trigger attribute_dependency_bump_version
  after insert or update or delete on catalog.attribute_dependency
  for each row execute function catalog.bump_from_attribute_ref();
