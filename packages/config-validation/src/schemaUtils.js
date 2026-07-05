/**
 * Recursively deletes every `required` array from a JSON Schema document.
 * Used to derive a "structural" variant of a schema for validating partial
 * overlay documents (configs/clients/<c>/config.json, .../theme.json, and the
 * per-environment overlays): the same type/enum/format/additionalProperties
 * constraints apply, but nothing needs to be *present* for the overlay to be
 * valid on its own — completeness is only required of the merged result.
 * See contract/README.md#development-schema-merge-model.
 */
export function stripRequiredRecursively(node) {
  if (Array.isArray(node)) {
    node.forEach(stripRequiredRecursively);
    return;
  }
  if (node && typeof node === "object") {
    delete node.required;
    for (const key of Object.keys(node)) {
      stripRequiredRecursively(node[key]);
    }
  }
}

/**
 * Returns a partial (required-stripped) clone of a JSON Schema document,
 * registered under a distinct $id so it can coexist in the same Ajv instance
 * as the original full schema.
 */
export function toPartialSchema(schema) {
  const clone = JSON.parse(JSON.stringify(schema));
  clone.$id = `${schema.$id}.partial`;
  stripRequiredRecursively(clone);
  return clone;
}
