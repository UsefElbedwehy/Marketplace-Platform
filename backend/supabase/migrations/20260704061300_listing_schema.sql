-- listing schema: the hybrid attribute value store ⭐
--
-- Resolves the classic EAV trap (docs/planning/05-dynamic-schema-engine.md §2,
-- ADR-0003): typed value rows (integrity + indexable) PLUS a denormalized
-- JSONB projection kept in sync by trigger (flexible, GIN-indexed filtering
-- and single-read hydration). A trigger enforces that every value matches its
-- catalog.attribute's data_type and validation rules — the database enforces
-- truth, Edge Functions enforce workflow.

create schema if not exists listing;

create table listing.listing (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references platform.tenant(id),
  owner_id uuid not null references auth.users(id),
  category_id uuid not null references catalog.category(id),
  title text not null,
  description text,
  price numeric,
  currency text,
  status text not null default 'draft'
    check (status in ('draft', 'pending_review', 'published', 'rejected', 'archived', 'sold')),
  -- Denormalized projection of listing_attribute_value, keyed by catalog.attribute.key,
  -- kept in sync by listing.attributes_index_sync_trigger below. This is what
  -- GET /v1/listings filters compile against.
  attributes_index jsonb not null default '{}'::jsonb,
  search_vector tsvector,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table listing.listing is
  'A marketplace listing. Attribute values live in listing_attribute_value (typed) and are projected here into attributes_index (JSONB) for fast filtering — see ADR-0003.';

create index listing_tenant_status_created_idx on listing.listing (tenant_id, status, created_at desc);
create index listing_category_idx on listing.listing (category_id);
create index listing_owner_idx on listing.listing (owner_id);
create index listing_attributes_index_gin on listing.listing using gin (attributes_index);
create index listing_search_vector_gin on listing.listing using gin (search_vector);

-- Deferred optimization path (not implemented here — see
-- docs/planning/09-cross-cutting.md#scalability): once real traffic identifies
-- specific hot, high-cardinality attributes per category (e.g. car year,
-- price-per-sqm), promote them to real generated columns + btree indexes via
-- a targeted migration. attributes_index + GIN is the v1 baseline; nothing
-- about the contract changes when that promotion happens.

create table listing.listing_attribute_value (
  listing_id uuid not null references listing.listing(id) on delete cascade,
  attribute_id uuid not null references catalog.attribute(id),
  value_text text,
  value_number numeric,
  value_bool boolean,
  value_date date,
  value_option_id uuid references catalog.attribute_option(id),
  value_option_ids uuid[],
  value_json jsonb,
  primary key (listing_id, attribute_id)
);

comment on table listing.listing_attribute_value is
  'One row per (listing, attribute). Exactly one value_* column is populated, matching the attribute''s data_type — enforced by enforce_attribute_value_type below.';

create index listing_attribute_value_attribute_idx on listing.listing_attribute_value (attribute_id);

create table listing.listing_media (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references listing.listing(id) on delete cascade,
  storage_path text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

comment on table listing.listing_media is
  'References to Storage objects (see docs/planning/03-backend-architecture.md §5) — not implemented in this migration beyond the table shape; upload/signing is Edge Function + Storage work.';

create index listing_media_listing_idx on listing.listing_media (listing_id);

-- === Grants ===================================================================

grant usage on schema listing to anon, authenticated, service_role;
grant select on listing.listing, listing.listing_attribute_value, listing.listing_media to anon, authenticated;
grant insert, update, delete on listing.listing, listing.listing_attribute_value, listing.listing_media to authenticated;
grant select, insert, update, delete on listing.listing, listing.listing_attribute_value, listing.listing_media to service_role;

-- === Type-enforcement trigger ================================================

create or replace function listing.enforce_attribute_value_type() returns trigger
language plpgsql as $$
declare
  v_data_type text;
  v_validation jsonb;
  v_populated_count int;
begin
  select data_type, validation into v_data_type, v_validation
    from catalog.attribute where id = new.attribute_id;

  if v_data_type is null then
    raise exception 'unknown attribute_id %', new.attribute_id;
  end if;

  v_populated_count :=
    (new.value_text is not null)::int + (new.value_number is not null)::int +
    (new.value_bool is not null)::int + (new.value_date is not null)::int +
    (new.value_option_id is not null)::int + (new.value_option_ids is not null)::int +
    (new.value_json is not null)::int;

  if v_populated_count <> 1 then
    raise exception 'exactly one value_* column must be set (got %) for attribute % (data_type=%)',
      v_populated_count, new.attribute_id, v_data_type;
  end if;

  if v_data_type = 'text' and new.value_text is null then
    raise exception 'attribute % is data_type=text, expected value_text to be set', new.attribute_id;
  elsif v_data_type = 'number' and new.value_number is null then
    raise exception 'attribute % is data_type=number, expected value_number to be set', new.attribute_id;
  elsif v_data_type = 'bool' and new.value_bool is null then
    raise exception 'attribute % is data_type=bool, expected value_bool to be set', new.attribute_id;
  elsif v_data_type = 'date' and new.value_date is null then
    raise exception 'attribute % is data_type=date, expected value_date to be set', new.attribute_id;
  elsif v_data_type = 'option' and new.value_option_id is null then
    raise exception 'attribute % is data_type=option, expected value_option_id to be set', new.attribute_id;
  elsif v_data_type = 'option_multi' and new.value_option_ids is null then
    raise exception 'attribute % is data_type=option_multi, expected value_option_ids to be set', new.attribute_id;
  elsif v_data_type in ('media', 'location') and new.value_json is null then
    raise exception 'attribute % is data_type=%, expected value_json to be set', new.attribute_id, v_data_type;
  end if;

  if v_data_type = 'number' and v_validation is not null then
    if v_validation ? 'min' and new.value_number < (v_validation ->> 'min')::numeric then
      raise exception 'value % is below min % for attribute %', new.value_number, v_validation ->> 'min', new.attribute_id;
    end if;
    if v_validation ? 'max' and new.value_number > (v_validation ->> 'max')::numeric then
      raise exception 'value % is above max % for attribute %', new.value_number, v_validation ->> 'max', new.attribute_id;
    end if;
  end if;

  if v_data_type = 'text' and v_validation is not null then
    if v_validation ? 'minLength' and length(new.value_text) < (v_validation ->> 'minLength')::int then
      raise exception 'value for attribute % is shorter than minLength %', new.attribute_id, v_validation ->> 'minLength';
    end if;
    if v_validation ? 'maxLength' and length(new.value_text) > (v_validation ->> 'maxLength')::int then
      raise exception 'value for attribute % is longer than maxLength %', new.attribute_id, v_validation ->> 'maxLength';
    end if;
    if v_validation ? 'pattern' and new.value_text !~ (v_validation ->> 'pattern') then
      raise exception 'value for attribute % does not match pattern %', new.attribute_id, v_validation ->> 'pattern';
    end if;
  end if;

  return new;
end;
$$;

create trigger listing_attribute_value_enforce_type
  before insert or update on listing.listing_attribute_value
  for each row execute function listing.enforce_attribute_value_type();

-- === attributes_index sync trigger ===========================================

create or replace function listing.sync_attributes_index(p_listing_id uuid) returns void
language plpgsql as $$
declare
  v_index jsonb;
begin
  select coalesce(jsonb_object_agg(a.key, resolved.value), '{}'::jsonb)
    into v_index
    from listing.listing_attribute_value lav
    join catalog.attribute a on a.id = lav.attribute_id
    cross join lateral (
      select case a.data_type
        when 'text' then to_jsonb(lav.value_text)
        when 'number' then to_jsonb(lav.value_number)
        when 'bool' then to_jsonb(lav.value_bool)
        when 'date' then to_jsonb(lav.value_date)
        when 'option' then to_jsonb((select o.value from catalog.attribute_option o where o.id = lav.value_option_id))
        when 'option_multi' then (
          select jsonb_agg(o.value) from catalog.attribute_option o where o.id = any(lav.value_option_ids)
        )
        else lav.value_json
      end as value
    ) resolved
    where lav.listing_id = p_listing_id;

  update listing.listing set attributes_index = v_index, updated_at = now() where id = p_listing_id;
end;
$$;

comment on function listing.sync_attributes_index is
  'Recomputes listing.attributes_index from listing_attribute_value, resolving option ids to their scalar `value` so filters like attributes_index @> ''{"brand":"bmw"}'' work without a join.';

create or replace function listing.attributes_index_sync_trigger() returns trigger
language plpgsql as $$
begin
  perform listing.sync_attributes_index(coalesce(new.listing_id, old.listing_id));
  return coalesce(new, old);
end;
$$;

create trigger listing_attribute_value_sync
  after insert or update or delete on listing.listing_attribute_value
  for each row execute function listing.attributes_index_sync_trigger();

-- === RLS ======================================================================

alter table listing.listing enable row level security;
alter table listing.listing_attribute_value enable row level security;
alter table listing.listing_media enable row level security;

create or replace function listing.is_moderator() returns boolean
  language sql stable
  as $$ select auth.role() = 'service_role' or platform.current_app_role() in ('moderator', 'admin', 'super_admin') $$;

-- Published listings are public (guest-first browsing); drafts/pending are
-- visible only to their owner or a moderator.
create policy listing_select on listing.listing
  for select
  using (
    (platform.current_tenant_id() is null or tenant_id = platform.current_tenant_id())
    and (status = 'published' or owner_id = auth.uid() or listing.is_moderator())
  );

create policy listing_insert_own on listing.listing
  for insert
  with check (owner_id = auth.uid() and tenant_id = platform.current_tenant_id());

-- Owners can edit their own listing while it's still a draft (once submitted,
-- only a moderator can change status — modeled by the OR clause, not a
-- separate status machine table for v1).
create policy listing_update_own_or_moderator on listing.listing
  for update
  using (owner_id = auth.uid() or listing.is_moderator())
  with check (owner_id = auth.uid() or listing.is_moderator());

create policy listing_delete_own_or_moderator on listing.listing
  for delete
  using (owner_id = auth.uid() or listing.is_moderator());

-- listing_attribute_value / listing_media: visibility and write follow the
-- parent listing exactly (same public-vs-owner-vs-moderator shape), via a join.
create policy listing_attribute_value_select on listing.listing_attribute_value
  for select
  using (exists (
    select 1 from listing.listing l
    where l.id = listing_attribute_value.listing_id
      and (platform.current_tenant_id() is null or l.tenant_id = platform.current_tenant_id())
      and (l.status = 'published' or l.owner_id = auth.uid() or listing.is_moderator())
  ));

create policy listing_attribute_value_write_owner on listing.listing_attribute_value
  for all
  using (exists (
    select 1 from listing.listing l where l.id = listing_attribute_value.listing_id and l.owner_id = auth.uid()
  ) or auth.role() = 'service_role')
  with check (exists (
    select 1 from listing.listing l where l.id = listing_attribute_value.listing_id and l.owner_id = auth.uid()
  ) or auth.role() = 'service_role');

create policy listing_media_select on listing.listing_media
  for select
  using (exists (
    select 1 from listing.listing l
    where l.id = listing_media.listing_id
      and (platform.current_tenant_id() is null or l.tenant_id = platform.current_tenant_id())
      and (l.status = 'published' or l.owner_id = auth.uid() or listing.is_moderator())
  ));

create policy listing_media_write_owner on listing.listing_media
  for all
  using (exists (
    select 1 from listing.listing l where l.id = listing_media.listing_id and l.owner_id = auth.uid()
  ) or auth.role() = 'service_role')
  with check (exists (
    select 1 from listing.listing l where l.id = listing_media.listing_id and l.owner_id = auth.uid()
  ) or auth.role() = 'service_role');
