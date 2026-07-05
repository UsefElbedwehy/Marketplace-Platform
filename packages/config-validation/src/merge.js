function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * Deep-merges `override` onto `base`. Arrays are replaced wholesale (not
 * concatenated or de-duped) — an overlay that specifies `locales.supported`
 * means exactly that list, matching how the platform's Development Schema
 * overlays are documented to behave (contract/README.md).
 */
export function deepMerge(base, override) {
  if (override === undefined) return base;
  if (isPlainObject(base) && isPlainObject(override)) {
    const result = { ...base };
    for (const key of Object.keys(override)) {
      result[key] = key in base ? deepMerge(base[key], override[key]) : override[key];
    }
    return result;
  }
  return override;
}
