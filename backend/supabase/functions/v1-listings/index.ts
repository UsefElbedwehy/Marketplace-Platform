// GET/POST /v1/listings, PATCH /v1/listings/{id} — the Dynamic Category &
// Attribute Engine's write + filter contract ⭐, plus the moderation status
// workflow. See docs/planning/05-dynamic-schema-engine.md §7 and
// contract/openapi/v1/openapi.yaml.

import { withRequestContext } from "../_shared/db.ts";
import { resolveClaims, type Claims } from "../_shared/auth.ts";
import { AppError, errorResponse, jsonResponse } from "../_shared/errors.ts";
import { isPreflight, newRequestId, withCors } from "../_shared/http.ts";
import { createListing, fetchListingById, fetchListings, updateListingStatus, type ListingFilters } from "../../../src/listing_service.ts";

const MODERATOR_ROLES = new Set(["moderator", "admin", "super_admin"]);
const listingByIdPattern = new URLPattern({ pathname: "/v1/listings/:id" });

function isModerator(claims: Claims): boolean {
  return !!claims.app_role && MODERATOR_ROLES.has(claims.app_role);
}

function parseFilters(url: URL, claims: Claims): ListingFilters {
  const filters: ListingFilters = {};
  const categoryId = url.searchParams.get("category");
  if (categoryId) filters.categoryId = categoryId;

  const status = url.searchParams.get("status");
  if (status) filters.status = status;

  const owner = url.searchParams.get("owner");
  if (owner === "me") filters.ownerId = claims.sub;

  const cursor = url.searchParams.get("cursor");
  if (cursor) filters.cursor = cursor;

  const limit = url.searchParams.get("limit");
  if (limit) filters.limit = Number(limit);

  const filtersParam = url.searchParams.get("filters");
  if (filtersParam) {
    try {
      filters.attributes = JSON.parse(filtersParam);
    } catch {
      throw new AppError(422, "validation_failed", "filters must be valid JSON.");
    }
  }
  return filters;
}

export async function handleListingsRequest(req: Request): Promise<Response> {
  if (isPreflight(req)) return withCors(new Response(null, { status: 204 }));

  const requestId = newRequestId();
  const url = new URL(req.url);

  try {
    const claims = await resolveClaims(req);

    if (req.method === "GET" && url.pathname === "/v1/listings") {
      const filters = parseFilters(url, claims);
      const { items, nextCursor } = await withRequestContext(claims, (client) => fetchListings(client, filters));
      return withCors(jsonResponse(200, { data: items, page: { nextCursor, hasMore: nextCursor !== null } }));
    }

    const getByIdMatch = req.method === "GET" ? listingByIdPattern.exec(url) : null;
    if (getByIdMatch) {
      const listingId = getByIdMatch.pathname.groups.id!;
      const listing = await withRequestContext(claims, (client) => fetchListingById(client, listingId));
      return withCors(jsonResponse(200, { data: listing }));
    }

    if (req.method === "POST" && url.pathname === "/v1/listings") {
      if (claims.role === "anon") {
        throw new AppError(401, "unauthorized", "Sign in to create a listing.");
      }
      const body = await req.json();
      if (!claims.tenant_id) {
        throw new AppError(422, "validation_failed", "Session is missing a tenant context.");
      }
      const listing = await withRequestContext(
        claims,
        (client) => createListing(client, claims.sub, claims.tenant_id!, body),
      );
      return withCors(jsonResponse(201, { data: listing }));
    }

    const patchMatch = req.method === "PATCH" ? listingByIdPattern.exec(url) : null;
    if (patchMatch) {
      if (claims.role === "anon") {
        throw new AppError(401, "unauthorized", "Sign in to update a listing.");
      }
      const listingId = patchMatch.pathname.groups.id!;
      const body = await req.json();
      if (!body.status) {
        throw new AppError(422, "validation_failed", "status is required.", [
          { field: "status", code: "required", message: "status is required" },
        ]);
      }
      const listing = await withRequestContext(
        claims,
        (client) => updateListingStatus(client, listingId, isModerator(claims), body.status),
      );
      return withCors(jsonResponse(200, { data: listing }));
    }

    throw new AppError(405, "method_not_allowed", `${req.method} is not supported on ${url.pathname}.`);
  } catch (err) {
    return withCors(errorResponse(err, requestId));
  }
}

if (import.meta.main) {
  Deno.serve(handleListingsRequest);
}
