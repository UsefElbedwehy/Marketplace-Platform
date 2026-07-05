// Re-exports the OpenAPI-generated component schemas so pages import one
// short path instead of reaching into @marketplace-platform/contract-types's
// generated output directly — and so there is exactly one place the
// dashboard's view of "what a category/schema/listing looks like" is typed
// from, matching what the backend actually serves (docs/planning/06 §8).

import type { ApiComponents } from "@marketplace-platform/contract-types";

export type CategoryTreeNode = ApiComponents["schemas"]["CategoryTreeNode"];
export type ComposedSchema = ApiComponents["schemas"]["ComposedSchema"];
export type SchemaGroup = ApiComponents["schemas"]["SchemaGroup"];
export type SchemaField = ApiComponents["schemas"]["SchemaField"];
export type AttributeOption = ApiComponents["schemas"]["AttributeOption"];
export type Listing = ApiComponents["schemas"]["Listing"];
export type UserProfile = ApiComponents["schemas"]["UserProfile"];
