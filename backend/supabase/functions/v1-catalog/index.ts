// GET /v1/categories/tree, GET /v1/categories/{id}/schema, GET /v1/attributes/{id}/options
// — the Dynamic Category & Attribute Engine's read contract ⭐. See
// docs/planning/05-dynamic-schema-engine.md §5 and contract/openapi/v1/openapi.yaml.
//
// Also the Schema Builder's write path (POST routes below) — the dashboard's
// category tree editor, attribute editor, and dependency builder
// (docs/planning/06-dashboard-architecture.md §3) write through here. RLS
// (catalog_write_editor et al.) is the actual enforcement: any authenticated
// caller can reach these handlers, but only catalog_editor/admin/super_admin
// rows survive the database's row-level security check.

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import {
  createAttribute,
  createAttributeDependency,
  createAttributeGroup,
  createAttributeOption,
  createCategory,
  fetchAttributeOptions,
  fetchCategorySchema,
  fetchCategoryTree,
} from "../../../src/catalog_service.ts";

const treePattern = new URLPattern({ pathname: "/v1/categories/tree" });
const categoriesPattern = new URLPattern({ pathname: "/v1/categories" });
const schemaPattern = new URLPattern({ pathname: "/v1/categories/:id/schema" });
const attributeGroupsPattern = new URLPattern({ pathname: "/v1/categories/:id/attribute-groups" });
const attributesPattern = new URLPattern({ pathname: "/v1/attribute-groups/:id/attributes" });
const optionsPattern = new URLPattern({ pathname: "/v1/attributes/:id/options" });
const dependenciesPattern = new URLPattern({ pathname: "/v1/attributes/:id/dependencies" });

function requireTenant(claims: { tenant_id?: string }): string {
  if (!claims.tenant_id) {
    throw new AppError(422, "validation_failed", "Session is missing a tenant context.");
  }
  return claims.tenant_id;
}

export async function handleCatalogRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);
  const locale = url.searchParams.get("locale") ?? "en";

  try {
    const claims = await resolveClaims(req);

    // --- reads ---
    if (req.method === "GET") {
      if (treePattern.test(url)) {
        const tree = await withRequestContext(claims, (client) => fetchCategoryTree(client, locale));
        return withCors(jsonResponse(200, { data: tree }));
      }

      const schemaMatch = schemaPattern.exec(url);
      if (schemaMatch) {
        const categoryId = schemaMatch.pathname.groups.id!;
        const schema = await withRequestContext(claims, (client) => fetchCategorySchema(client, categoryId, locale));
        return withCors(jsonResponse(200, { data: schema }));
      }

      const optionsMatch = optionsPattern.exec(url);
      if (optionsMatch) {
        const attributeId = optionsMatch.pathname.groups.id!;
        const parentOptionId = url.searchParams.get("parent");
        const limit = Math.min(Number(url.searchParams.get("limit") ?? "50"), 200);
        const offset = Number(url.searchParams.get("offset") ?? "0");
        const options = await withRequestContext(
          claims,
          (client) => fetchAttributeOptions(client, attributeId, parentOptionId, locale, limit, offset),
        );
        return withCors(jsonResponse(200, { data: options }));
      }
    }

    // --- writes (Schema Builder) ---
    if (req.method === "POST") {
      if (categoriesPattern.test(url)) {
        const tenantId = requireTenant(claims);
        const body = await req.json();
        const result = await withRequestContext(claims, (client) => createCategory(client, tenantId, body));
        return withCors(jsonResponse(201, { data: result }));
      }

      const groupMatch = attributeGroupsPattern.exec(url);
      if (groupMatch) {
        const categoryId = groupMatch.pathname.groups.id!;
        const body = await req.json();
        const result = await withRequestContext(claims, (client) => createAttributeGroup(client, { ...body, categoryId }));
        return withCors(jsonResponse(201, { data: result }));
      }

      const attributeMatch = attributesPattern.exec(url);
      if (attributeMatch) {
        const groupId = attributeMatch.pathname.groups.id!;
        const body = await req.json();
        const result = await withRequestContext(claims, (client) => createAttribute(client, { ...body, groupId }));
        return withCors(jsonResponse(201, { data: result }));
      }

      const optionMatch = optionsPattern.exec(url);
      if (optionMatch) {
        const attributeId = optionMatch.pathname.groups.id!;
        const body = await req.json();
        const result = await withRequestContext(claims, (client) => createAttributeOption(client, { ...body, attributeId }));
        return withCors(jsonResponse(201, { data: result }));
      }

      const dependencyMatch = dependenciesPattern.exec(url);
      if (dependencyMatch) {
        const attributeId = dependencyMatch.pathname.groups.id!;
        const body = await req.json();
        const result = await withRequestContext(claims, (client) => createAttributeDependency(client, { ...body, attributeId }));
        return withCors(jsonResponse(201, { data: result }));
      }
    }

    throw new AppError(404, "not_found", `No route for ${req.method} ${url.pathname}`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleCatalogRequest);
}
