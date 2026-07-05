import { assertEquals, assertRejects } from "jsr:@std/assert@^1";
import { fetchAttributeOptions, fetchCategorySchema, fetchCategoryTree } from "./catalog_service.ts";
import { AppError } from "./errors.ts";
import type { QueryExecutor, QueryResult } from "./query_executor.ts";

/** Dispatches based on a substring of the SQL text so call order doesn't matter. */
function fakeExecutor(routes: Array<{ match: string; rows: unknown[] }>): QueryExecutor {
  return {
    // deno-lint-ignore require-await
    async queryObject<T>(sql: string): Promise<QueryResult<T>> {
      const route = routes.find((r) => sql.includes(r.match));
      return { rows: (route?.rows ?? []) as T[] };
    },
  };
}

Deno.test("fetchCategoryTree nests children under their parent, ordered", async () => {
  const db = fakeExecutor([
    {
      match: "from catalog.category where is_active",
      rows: [
        { id: "vehicles", parent_id: null, slug: "vehicles", name_i18n: { en: "Vehicles" }, icon: null, sort_order: 1, is_leaf: false },
        { id: "cars", parent_id: "vehicles", slug: "cars", name_i18n: { en: "Cars" }, icon: null, sort_order: 1, is_leaf: true },
        { id: "moto", parent_id: "vehicles", slug: "motorcycles", name_i18n: { en: "Motorcycles" }, icon: null, sort_order: 2, is_leaf: true },
      ],
    },
  ]);

  const tree = await fetchCategoryTree(db, "en");
  assertEquals(tree.length, 1);
  assertEquals(tree[0].name, "Vehicles");
  assertEquals(tree[0].children.map((c) => c.slug), ["cars", "motorcycles"]);
});

Deno.test("fetchCategoryTree resolves locale with English fallback", async () => {
  const db = fakeExecutor([
    {
      match: "from catalog.category where is_active",
      rows: [{ id: "x", parent_id: null, slug: "x", name_i18n: { en: "Cars" }, icon: null, sort_order: 1, is_leaf: true }],
    },
  ]);
  const tree = await fetchCategoryTree(db, "ar");
  assertEquals(tree[0].name, "Cars");
});

Deno.test("fetchCategorySchema throws 404 for an unknown category", async () => {
  const db = fakeExecutor([{ match: "select id, slug, name_i18n, schema_version", rows: [] }]);
  const err = await assertRejects(() => fetchCategorySchema(db, "missing", "en"), AppError);
  assertEquals(err.status, 404);
});

Deno.test("fetchCategorySchema composes category + path + groups + fields + options + dependencies", async () => {
  const db = fakeExecutor([
    { match: "select id, slug, name_i18n, schema_version", rows: [{ id: "cars", slug: "cars", name_i18n: { en: "Cars" }, schema_version: 7 }] },
    { match: "with recursive path", rows: [{ name_i18n: { en: "Vehicles" } }, { name_i18n: { en: "Cars" } }] },
    { match: "from catalog.attribute_group", rows: [{ id: "g1", name_i18n: { en: "Details" }, sort_order: 1, is_collapsible: false }] },
    {
      match: "from catalog.attribute\n",
      rows: [
        { id: "brand", group_id: "g1", key: "brand", label_i18n: { en: "Brand" }, data_type: "option", input_type: "dropdown", validation: {}, default_value: null, is_required: true, is_filterable: true, is_searchable: false, sort_order: 1, unit: null },
        { id: "model", group_id: "g1", key: "model", label_i18n: { en: "Model" }, data_type: "option", input_type: "dropdown", validation: {}, default_value: null, is_required: true, is_filterable: false, is_searchable: false, sort_order: 2, unit: null },
      ],
    },
    { match: "from catalog.attribute_option", rows: [{ id: "opt1", attribute_id: "brand", value: "bmw", label_i18n: { en: "BMW" }, parent_option_id: null }] },
    { match: "from catalog.attribute_dependency", rows: [{ attribute_id: "model", depends_on_id: "brand", rule: "options_filtered_by", condition: {} }] },
  ]);

  const schema = await fetchCategorySchema(db, "cars", "en");
  assertEquals(schema.schemaVersion, 7);
  assertEquals(schema.category.path, ["Vehicles", "Cars"]);
  assertEquals(schema.groups.length, 1);
  assertEquals(schema.groups[0].fields.length, 2);
  assertEquals(schema.groups[0].fields[0].options, [{ id: "opt1", value: "bmw", label: "BMW", parentOptionId: null }]);
  assertEquals(schema.groups[0].fields[1].dependsOn, [{ field: "brand", rule: "options_filtered_by", condition: {} }]);
});

Deno.test("fetchCategorySchema returns an empty groups array for a category with no attribute schema", async () => {
  const db = fakeExecutor([
    { match: "select id, slug, name_i18n, schema_version", rows: [{ id: "misc", slug: "miscellaneous", name_i18n: { en: "Misc" }, schema_version: 1 }] },
    { match: "with recursive path", rows: [{ name_i18n: { en: "Misc" } }] },
    { match: "from catalog.attribute_group", rows: [] },
  ]);
  const schema = await fetchCategorySchema(db, "misc", "en");
  assertEquals(schema.groups, []);
});

Deno.test("fetchAttributeOptions maps rows to the contract shape", async () => {
  const db = fakeExecutor([
    { match: "from catalog.attribute_option", rows: [{ id: "o1", value: "x5", label_i18n: { en: "X5" }, parent_option_id: "bmw" }] },
  ]);
  const options = await fetchAttributeOptions(db, "model", "bmw", "en", 20, 0);
  assertEquals(options, [{ id: "o1", value: "x5", label: "X5", parentOptionId: "bmw" }]);
});
