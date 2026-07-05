"use client";

// The Schema Builder's live preview: renders the SAME schema contract the
// app would (docs/planning/06-dashboard-architecture.md §3 — "Live preview
// renders the actual dynamic form... so admins see exactly what users will
// see"). This is a web stand-in for the iOS DynamicForms module (Phase 4);
// the point being proven is identical either way — one generic renderer, any
// category's structurally different schema, driven entirely by metadata.

import type { SchemaField, SchemaGroup } from "@/lib/contract-types";

export function DynamicFormPreview({
  groups,
  values,
  onChange,
}: {
  groups: SchemaGroup[];
  values: Record<string, unknown>;
  onChange: (key: string, value: unknown) => void;
}) {
  const allFields = groups.flatMap((g) => g.fields);
  const fieldsByKey = new Map(allFields.map((f) => [f.key, f]));

  return (
    <div className="space-y-5">
      {groups.length === 0 && (
        <p className="text-sm text-slate-500">
          This category has no custom attributes — the listing form is just title/description/price/media.
        </p>
      )}
      {groups.map((group) => (
        <div key={group.id}>
          <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">{group.name}</h3>
          <div className="space-y-3">
            {[...group.fields]
              .sort((a, b) => a.sortOrder - b.sortOrder)
              .map((field) => (
                <DynamicField key={field.key} field={field} fieldsByKey={fieldsByKey} values={values} onChange={onChange} />
              ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function isVisible(field: SchemaField, values: Record<string, unknown>): boolean {
  const rule = field.dependsOn.find((d) => d.rule === "visible_when");
  if (!rule) return true;
  const condition = rule.condition as { equals?: unknown };
  return "equals" in condition ? values[rule.field] === condition.equals : true;
}

/** Resolves `options_filtered_by`: the parent's *selected value* (a string) must
 * first resolve to the parent option's *id* before it can filter the child's
 * options by parentOptionId — the two are different things. */
function resolveVisibleOptions(
  field: SchemaField,
  fieldsByKey: Map<string, SchemaField>,
  values: Record<string, unknown>,
): SchemaField["options"] {
  const filterRule = field.dependsOn.find((d) => d.rule === "options_filtered_by");
  if (!filterRule) return field.options;

  const parentField = fieldsByKey.get(filterRule.field);
  const parentSelectedValue = values[filterRule.field];
  if (!parentField || parentSelectedValue === undefined || parentSelectedValue === null || parentSelectedValue === "") {
    return [];
  }
  const parentOption = parentField.options.find((o) => o.value === parentSelectedValue);
  if (!parentOption) return [];

  return field.options.filter((o) => o.parentOptionId === parentOption.id);
}

function DynamicField({
  field,
  fieldsByKey,
  values,
  onChange,
}: {
  field: SchemaField;
  fieldsByKey: Map<string, SchemaField>;
  values: Record<string, unknown>;
  onChange: (key: string, value: unknown) => void;
}) {
  if (!isVisible(field, values)) return null;

  const filterRule = field.dependsOn.find((d) => d.rule === "options_filtered_by");
  const visibleOptions = resolveVisibleOptions(field, fieldsByKey, values);

  return (
    <label className="block text-sm">
      <span className="mb-1 flex items-center gap-2 text-slate-700">
        {field.label}
        {field.required && <span className="text-red-500">*</span>}
        {field.unit && <span className="text-xs text-slate-400">({field.unit})</span>}
      </span>
      <FieldInput field={field} value={values[field.key]} options={visibleOptions} onChange={(v) => onChange(field.key, v)} />
      {filterRule && (
        <span className="mt-1 block text-xs text-slate-400">
          options filtered by {filterRule.field}
          {values[filterRule.field] ? ` = ${String(values[filterRule.field])}` : " (choose it first)"}
        </span>
      )}
    </label>
  );
}

function FieldInput({
  field,
  value,
  options,
  onChange,
}: {
  field: SchemaField;
  value: unknown;
  options: SchemaField["options"];
  onChange: (v: unknown) => void;
}) {
  switch (field.inputType) {
    case "textarea":
      return (
        <textarea className="input" rows={3} value={(value as string) ?? ""} onChange={(e) => onChange(e.target.value)} />
      );
    case "switch":
      return (
        <input type="checkbox" checked={Boolean(value)} onChange={(e) => onChange(e.target.checked)} className="h-4 w-4" />
      );
    case "datepicker":
      return <input type="date" className="input" value={(value as string) ?? ""} onChange={(e) => onChange(e.target.value)} />;
    case "stepper":
    case "slider":
      return (
        <input
          type="number"
          className="input"
          value={(value as number) ?? ""}
          onChange={(e) => onChange(e.target.value === "" ? undefined : Number(e.target.value))}
        />
      );
    case "dropdown":
      return (
        <select className="input" value={(value as string) ?? ""} onChange={(e) => onChange(e.target.value)}>
          <option value="">Select…</option>
          {options.map((o) => (
            <option key={o.id} value={o.value}>
              {o.label}
            </option>
          ))}
        </select>
      );
    case "chips":
      return (
        <div className="flex flex-wrap gap-2">
          {options.map((o) => {
            const selected = Array.isArray(value) && value.includes(o.value);
            return (
              <button
                type="button"
                key={o.id}
                onClick={() => {
                  const current = Array.isArray(value) ? (value as string[]) : [];
                  onChange(selected ? current.filter((v) => v !== o.value) : [...current, o.value]);
                }}
                className={`rounded-full border px-3 py-1 text-xs ${
                  selected ? "border-slate-900 bg-slate-900 text-white" : "border-slate-300 text-slate-600"
                }`}
              >
                {o.label}
              </button>
            );
          })}
        </div>
      );
    case "media":
    case "map":
      return (
        <div className="rounded border border-dashed border-slate-300 px-3 py-4 text-center text-xs text-slate-400">
          {field.inputType} picker (not implemented in this preview)
        </div>
      );
    default:
      return <input type="text" className="input" value={(value as string) ?? ""} onChange={(e) => onChange(e.target.value)} />;
  }
}
