// Resolves a contract/schema/common.schema.json#/$defs/localizedString map to
// a single string for the requested locale — server-side locale resolution
// per docs/planning/05-dynamic-schema-engine.md §5 ("clients don't juggle
// translation logic"). Falls back to English, then whatever's first.

export function resolveI18n(map: Record<string, string> | null | undefined, locale: string): string {
  if (!map) return "";
  if (map[locale]) return map[locale];
  if (map["en"]) return map["en"];
  const first = Object.values(map)[0];
  return first ?? "";
}
