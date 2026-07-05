// The Dynamic Category & Attribute Engine's contract-facing composition
// layer ⭐ — turns the normalized catalog.* tables into the schema shape
// DynamicForms (and the dashboard's Schema Builder preview) render from. See
// docs/planning/05-dynamic-schema-engine.md §5.

import type { QueryExecutor } from "./query_executor.ts";
import { AppError, type FieldError } from "./errors.ts";
import { resolveI18n } from "./i18n.ts";

type I18nMap = Record<string, string>;

export interface CategoryTreeNode {
  id: string;
  slug: string;
  name: string;
  icon: string | null;
  sortOrder: number;
  isLeaf: boolean;
  children: CategoryTreeNode[];
}

export interface AttributeOption {
  id: string;
  value: string;
  label: string;
  parentOptionId: string | null;
}

export interface AttributeDependency {
  field: string;
  rule: string;
  condition: Record<string, unknown>;
}

export interface SchemaField {
  id: string;
  key: string;
  label: string;
  dataType: string;
  inputType: string;
  required: boolean;
  filterable: boolean;
  searchable: boolean;
  sortOrder: number;
  unit: string | null;
  validation: Record<string, unknown>;
  defaultValue: unknown;
  options: AttributeOption[];
  dependsOn: AttributeDependency[];
}

export interface SchemaGroup {
  id: string;
  name: string;
  collapsible: boolean;
  fields: SchemaField[];
}

export interface ComposedSchema {
  schemaVersion: number;
  category: { id: string; slug: string; name: string; path: string[] };
  groups: SchemaGroup[];
}

export async function fetchCategoryTree(db: QueryExecutor, locale: string): Promise<CategoryTreeNode[]> {
  const result = await db.queryObject<{
    id: string;
    parent_id: string | null;
    slug: string;
    name_i18n: I18nMap;
    icon: string | null;
    sort_order: number;
    is_leaf: boolean;
  }>(
    "select id, parent_id, slug, name_i18n, icon, sort_order, is_leaf from catalog.category where is_active order by sort_order",
  );

  const nodesById = new Map<string, CategoryTreeNode>();
  for (const row of result.rows) {
    nodesById.set(row.id, {
      id: row.id,
      slug: row.slug,
      name: resolveI18n(row.name_i18n, locale),
      icon: row.icon,
      sortOrder: row.sort_order,
      isLeaf: row.is_leaf,
      children: [],
    });
  }

  const roots: CategoryTreeNode[] = [];
  for (const row of result.rows) {
    const node = nodesById.get(row.id)!;
    const parent = row.parent_id ? nodesById.get(row.parent_id) : undefined;
    if (parent) {
      parent.children.push(node);
    } else {
      roots.push(node);
    }
  }
  return roots;
}

export async function fetchCategorySchema(
  db: QueryExecutor,
  categoryId: string,
  locale: string,
): Promise<ComposedSchema> {
  const catResult = await db.queryObject<{ id: string; slug: string; name_i18n: I18nMap; schema_version: number }>(
    "select id, slug, name_i18n, schema_version from catalog.category where id = $1",
    [categoryId],
  );
  if (catResult.rows.length === 0) {
    throw new AppError(404, "not_found", `Category ${categoryId} not found.`);
  }
  const category = catResult.rows[0];

  const pathResult = await db.queryObject<{ name_i18n: I18nMap }>(
    `with recursive path as (
       select id, parent_id, name_i18n, 0 as depth from catalog.category where id = $1
       union all
       select c.id, c.parent_id, c.name_i18n, p.depth + 1
       from catalog.category c join path p on c.id = p.parent_id
     )
     select name_i18n from path order by depth desc`,
    [categoryId],
  );
  const path = pathResult.rows.map((r) => resolveI18n(r.name_i18n, locale));

  const groupsResult = await db.queryObject<
    { id: string; name_i18n: I18nMap; sort_order: number; is_collapsible: boolean }
  >(
    "select id, name_i18n, sort_order, is_collapsible from catalog.attribute_group where category_id = $1 order by sort_order",
    [categoryId],
  );

  const groupIds = groupsResult.rows.map((g) => g.id);
  const categoryHeader = { id: category.id, slug: category.slug, name: resolveI18n(category.name_i18n, locale), path };

  if (groupIds.length === 0) {
    return { schemaVersion: category.schema_version, category: categoryHeader, groups: [] };
  }

  const attrsResult = await db.queryObject<{
    id: string;
    group_id: string;
    key: string;
    label_i18n: I18nMap;
    data_type: string;
    input_type: string;
    validation: Record<string, unknown> | null;
    default_value: unknown;
    is_required: boolean;
    is_filterable: boolean;
    is_searchable: boolean;
    sort_order: number;
    unit: string | null;
  }>(
    `select id, group_id, key, label_i18n, data_type, input_type, validation, default_value,
            is_required, is_filterable, is_searchable, sort_order, unit
     from catalog.attribute
     where group_id = any($1) and is_active
     order by sort_order`,
    [groupIds],
  );

  const attrIds = attrsResult.rows.map((a) => a.id);
  const keyById = new Map(attrsResult.rows.map((a) => [a.id, a.key]));

  const optionsResult = attrIds.length > 0
    ? await db.queryObject<{ id: string; attribute_id: string; value: string; label_i18n: I18nMap; parent_option_id: string | null }>(
      "select id, attribute_id, value, label_i18n, parent_option_id from catalog.attribute_option where attribute_id = any($1) and is_active order by sort_order",
      [attrIds],
    )
    : { rows: [] as { id: string; attribute_id: string; value: string; label_i18n: I18nMap; parent_option_id: string | null }[] };

  const depsResult = attrIds.length > 0
    ? await db.queryObject<
      { attribute_id: string; depends_on_id: string; rule: string; condition: Record<string, unknown> }
    >(
      "select attribute_id, depends_on_id, rule, condition from catalog.attribute_dependency where attribute_id = any($1)",
      [attrIds],
    )
    : { rows: [] as { attribute_id: string; depends_on_id: string; rule: string; condition: Record<string, unknown> }[] };

  const optionsByAttr = new Map<string, AttributeOption[]>();
  for (const o of optionsResult.rows) {
    const list = optionsByAttr.get(o.attribute_id) ?? [];
    list.push({ id: o.id, value: o.value, label: resolveI18n(o.label_i18n, locale), parentOptionId: o.parent_option_id });
    optionsByAttr.set(o.attribute_id, list);
  }

  const depsByAttr = new Map<string, AttributeDependency[]>();
  for (const d of depsResult.rows) {
    const list = depsByAttr.get(d.attribute_id) ?? [];
    list.push({ field: keyById.get(d.depends_on_id) ?? d.depends_on_id, rule: d.rule, condition: d.condition });
    depsByAttr.set(d.attribute_id, list);
  }

  const fieldsByGroup = new Map<string, SchemaField[]>();
  for (const a of attrsResult.rows) {
    const list = fieldsByGroup.get(a.group_id) ?? [];
    list.push({
      id: a.id,
      key: a.key,
      label: resolveI18n(a.label_i18n, locale),
      dataType: a.data_type,
      inputType: a.input_type,
      required: a.is_required,
      filterable: a.is_filterable,
      searchable: a.is_searchable,
      sortOrder: a.sort_order,
      unit: a.unit,
      validation: a.validation ?? {},
      defaultValue: a.default_value ?? null,
      options: optionsByAttr.get(a.id) ?? [],
      dependsOn: depsByAttr.get(a.id) ?? [],
    });
    fieldsByGroup.set(a.group_id, list);
  }

  const groups: SchemaGroup[] = groupsResult.rows.map((g) => ({
    id: g.id,
    name: resolveI18n(g.name_i18n, locale),
    collapsible: g.is_collapsible,
    fields: (fieldsByGroup.get(g.id) ?? []).sort((a, b) => a.sortOrder - b.sortOrder),
  }));

  return { schemaVersion: category.schema_version, category: categoryHeader, groups };
}

export async function fetchAttributeOptions(
  db: QueryExecutor,
  attributeId: string,
  parentOptionId: string | null,
  locale: string,
  limit: number,
  offset: number,
): Promise<AttributeOption[]> {
  const result = await db.queryObject<{ id: string; value: string; label_i18n: I18nMap; parent_option_id: string | null }>(
    `select id, value, label_i18n, parent_option_id from catalog.attribute_option
     where attribute_id = $1 and is_active
       and ($2::uuid is null or parent_option_id = $2)
     order by sort_order
     limit $3 offset $4`,
    [attributeId, parentOptionId, limit, offset],
  );
  return result.rows.map((o) => ({
    id: o.id,
    value: o.value,
    label: resolveI18n(o.label_i18n, locale),
    parentOptionId: o.parent_option_id,
  }));
}

// === Schema Builder write path ===============================================
// RLS (catalog_write_editor et al.) is the actual enforcement — these are
// reachable by any authenticated caller at the HTTP layer, exactly like the
// read path, and the database rejects writes from non-catalog_editor/admin
// roles regardless. See docs/planning/06-dashboard-architecture.md §3.

export interface CreateCategoryInput {
  parentId: string | null;
  slug: string;
  nameI18n: I18nMap;
  icon?: string | null;
  sortOrder?: number;
  isLeaf?: boolean;
}

export async function createCategory(db: QueryExecutor, tenantId: string, input: CreateCategoryInput) {
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(input.slug)) {
    throw new AppError(422, "validation_failed", "slug must be kebab-case.", [
      { field: "slug", code: "invalid_format", message: "slug must be kebab-case (e.g. real-estate)" },
    ]);
  }
  const result = await db.queryObject<{ id: string }>(
    `insert into catalog.category (tenant_id, parent_id, slug, name_i18n, icon, sort_order, is_leaf)
     values ($1, $2, $3, $4::jsonb, $5, $6, $7)
     returning id`,
    [
      tenantId,
      input.parentId,
      input.slug,
      JSON.stringify(input.nameI18n),
      input.icon ?? null,
      input.sortOrder ?? 0,
      input.isLeaf ?? true,
    ],
  );
  return { id: result.rows[0].id };
}

export interface CreateAttributeGroupInput {
  categoryId: string;
  nameI18n: I18nMap;
  sortOrder?: number;
  isCollapsible?: boolean;
}

export async function createAttributeGroup(db: QueryExecutor, input: CreateAttributeGroupInput) {
  const result = await db.queryObject<{ id: string }>(
    `insert into catalog.attribute_group (category_id, name_i18n, sort_order, is_collapsible)
     values ($1, $2::jsonb, $3, $4)
     returning id`,
    [input.categoryId, JSON.stringify(input.nameI18n), input.sortOrder ?? 0, input.isCollapsible ?? false],
  );
  return { id: result.rows[0].id };
}

export interface CreateAttributeInput {
  groupId: string;
  key: string;
  labelI18n: I18nMap;
  dataType: string;
  inputType: string;
  validation?: Record<string, unknown>;
  defaultValue?: unknown;
  isRequired?: boolean;
  isFilterable?: boolean;
  isSearchable?: boolean;
  sortOrder?: number;
  unit?: string | null;
}

const ATTRIBUTE_KEY_PATTERN = /^[a-zA-Z][a-zA-Z0-9_]*$/;
const VALID_DATA_TYPES = ["text", "number", "bool", "date", "option", "option_multi", "media", "location"];
const VALID_INPUT_TYPES = [
  "textfield",
  "textarea",
  "stepper",
  "slider",
  "dropdown",
  "chips",
  "switch",
  "datepicker",
  "media",
  "map",
];

export async function createAttribute(db: QueryExecutor, input: CreateAttributeInput) {
  const fieldErrors: FieldError[] = [];
  if (!ATTRIBUTE_KEY_PATTERN.test(input.key)) {
    fieldErrors.push({ field: "key", code: "invalid_format", message: "key must be alphanumeric/underscore." });
  }
  if (!VALID_DATA_TYPES.includes(input.dataType)) {
    fieldErrors.push({ field: "dataType", code: "invalid_enum", message: `dataType must be one of ${VALID_DATA_TYPES.join(", ")}` });
  }
  if (!VALID_INPUT_TYPES.includes(input.inputType)) {
    fieldErrors.push({ field: "inputType", code: "invalid_enum", message: `inputType must be one of ${VALID_INPUT_TYPES.join(", ")}` });
  }
  if (fieldErrors.length > 0) {
    throw new AppError(422, "validation_failed", "Invalid attribute definition.", fieldErrors);
  }

  const result = await db.queryObject<{ id: string }>(
    `insert into catalog.attribute
       (group_id, key, label_i18n, data_type, input_type, validation, default_value, is_required, is_filterable, is_searchable, sort_order, unit)
     values ($1, $2, $3::jsonb, $4, $5, $6::jsonb, $7::jsonb, $8, $9, $10, $11, $12)
     returning id`,
    [
      input.groupId,
      input.key,
      JSON.stringify(input.labelI18n),
      input.dataType,
      input.inputType,
      JSON.stringify(input.validation ?? {}),
      input.defaultValue !== undefined ? JSON.stringify(input.defaultValue) : null,
      input.isRequired ?? false,
      input.isFilterable ?? false,
      input.isSearchable ?? false,
      input.sortOrder ?? 0,
      input.unit ?? null,
    ],
  );
  return { id: result.rows[0].id };
}

export interface CreateAttributeOptionInput {
  attributeId: string;
  parentOptionId?: string | null;
  value: string;
  labelI18n: I18nMap;
  sortOrder?: number;
}

export async function createAttributeOption(db: QueryExecutor, input: CreateAttributeOptionInput) {
  const result = await db.queryObject<{ id: string }>(
    `insert into catalog.attribute_option (attribute_id, parent_option_id, value, label_i18n, sort_order)
     values ($1, $2, $3, $4::jsonb, $5)
     returning id`,
    [input.attributeId, input.parentOptionId ?? null, input.value, JSON.stringify(input.labelI18n), input.sortOrder ?? 0],
  );
  return { id: result.rows[0].id };
}

export interface CreateAttributeDependencyInput {
  attributeId: string;
  dependsOnId: string;
  rule: string;
  condition?: Record<string, unknown>;
}

const VALID_DEPENDENCY_RULES = ["visible_when", "required_when", "options_filtered_by"];

export async function createAttributeDependency(db: QueryExecutor, input: CreateAttributeDependencyInput) {
  if (!VALID_DEPENDENCY_RULES.includes(input.rule)) {
    throw new AppError(422, "validation_failed", `rule must be one of ${VALID_DEPENDENCY_RULES.join(", ")}`, [
      { field: "rule", code: "invalid_enum", message: `rule must be one of ${VALID_DEPENDENCY_RULES.join(", ")}` },
    ]);
  }
  const result = await db.queryObject<{ id: string }>(
    `insert into catalog.attribute_dependency (attribute_id, depends_on_id, rule, condition)
     values ($1, $2, $3, $4::jsonb)
     returning id`,
    [input.attributeId, input.dependsOnId, input.rule, JSON.stringify(input.condition ?? {})],
  );
  return { id: result.rows[0].id };
}
