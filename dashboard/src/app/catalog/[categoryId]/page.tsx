"use client";

import { use, useState } from "react";
import Link from "next/link";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import type { ComposedSchema } from "@/lib/contract-types";
import { useAuth } from "@/components/AuthProvider";
import { DynamicFormPreview } from "@/components/DynamicFieldPreview";

const DATA_TYPES = ["text", "number", "bool", "date", "option", "option_multi", "media", "location"];
const INPUT_TYPES = ["textfield", "textarea", "stepper", "slider", "dropdown", "chips", "switch", "datepicker", "media", "map"];

export default function CategoryDetailPage({ params }: { params: Promise<{ categoryId: string }> }) {
  const { categoryId } = use(params);
  const { data: schema, loading, error, reload } = useApi<ComposedSchema>(`/v1/categories/${categoryId}/schema?locale=en`);
  const { session } = useAuth();
  const canWrite = session?.appRole === "catalog_editor" || session?.appRole === "admin" || session?.appRole === "super_admin";
  const [previewValues, setPreviewValues] = useState<Record<string, unknown>>({});

  if (loading) return <p className="text-sm text-slate-500">Loading…</p>;
  if (error) return <p className="text-sm text-red-600">{(error as Error).message}</p>;
  if (!schema) return null;

  return (
    <div className="space-y-6">
      <div>
        <Link href="/catalog" className="text-xs text-slate-500 hover:underline">
          ← Category tree
        </Link>
        <h1 className="text-lg font-semibold">{schema.category.path.join(" › ")}</h1>
        <p className="text-xs text-slate-500">
          schemaVersion {schema.schemaVersion} — bumps on every structural change (ETag for client caching)
        </p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <div className="space-y-4">
          <Section title="Attribute groups & fields">
            {schema.groups.length === 0 && <p className="text-sm text-slate-500">No custom schema yet.</p>}
            {schema.groups.map((group) => (
              <div key={group.id} className="mb-4 rounded border border-slate-200 p-3">
                <h3 className="text-sm font-semibold">{group.name}</h3>
                <table className="mt-2 w-full text-xs">
                  <tbody>
                    {group.fields.map((f) => (
                      <tr key={f.key} className="border-t border-slate-100">
                        <td className="py-1 pr-2 font-medium">{f.key}</td>
                        <td className="py-1 pr-2 text-slate-500">{f.dataType}/{f.inputType}</td>
                        <td className="py-1 pr-2">{f.required ? "required" : ""}</td>
                        <td className="py-1 text-slate-400">{f.options.length > 0 ? `${f.options.length} options` : ""}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {canWrite && <AddAttributeForm groupId={group.id} onCreated={reload} />}
                {canWrite && <AddOptionForms fields={group.fields} onCreated={reload} />}
              </div>
            ))}
          </Section>

          {canWrite && <AddAttributeGroupForm categoryId={categoryId} onCreated={reload} />}
        </div>

        <div>
          <Section title="Live preview — schema-driven, not screen-driven">
            <DynamicFormPreview groups={schema.groups} values={previewValues} onChange={(k, v) => setPreviewValues((p) => ({ ...p, [k]: v }))} />
          </Section>
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border border-slate-200 bg-white p-5">
      <h2 className="mb-3 text-sm font-semibold text-slate-800">{title}</h2>
      {children}
    </div>
  );
}

function AddAttributeGroupForm({ categoryId, onCreated }: { categoryId: string; onCreated: () => void }) {
  const [name, setName] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post(`/v1/categories/${categoryId}/attribute-groups`, { nameI18n: { en: name } });
      setName("");
      onCreated();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create group");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="rounded-lg border border-slate-200 bg-white p-5 space-y-2">
      <h2 className="text-sm font-semibold">New attribute group</h2>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="Group name (e.g. Details)" className="input" required />
      {error && <p className="text-xs text-red-600">{error}</p>}
      <button type="submit" disabled={busy} className="btn-secondary">
        {busy ? "Creating…" : "Add group"}
      </button>
    </form>
  );
}

function AddAttributeForm({ groupId, onCreated }: { groupId: string; onCreated: () => void }) {
  const [key, setKey] = useState("");
  const [label, setLabel] = useState("");
  const [dataType, setDataType] = useState("text");
  const [inputType, setInputType] = useState("textfield");
  const [isRequired, setIsRequired] = useState(false);
  const [isFilterable, setIsFilterable] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post(`/v1/attribute-groups/${groupId}/attributes`, {
        key,
        labelI18n: { en: label },
        dataType,
        inputType,
        isRequired,
        isFilterable,
      });
      setKey("");
      setLabel("");
      onCreated();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create attribute");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="mt-3 space-y-2 rounded border border-dashed border-slate-300 p-3">
      <p className="text-xs font-semibold text-slate-600">Add attribute</p>
      <div className="grid grid-cols-2 gap-2">
        <input value={key} onChange={(e) => setKey(e.target.value)} placeholder="key (e.g. brand)" className="input" required />
        <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Label" className="input" required />
        <select value={dataType} onChange={(e) => setDataType(e.target.value)} className="input">
          {DATA_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
        <select value={inputType} onChange={(e) => setInputType(e.target.value)} className="input">
          {INPUT_TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
      </div>
      <label className="flex items-center gap-2 text-xs">
        <input type="checkbox" checked={isRequired} onChange={(e) => setIsRequired(e.target.checked)} /> required
      </label>
      <label className="flex items-center gap-2 text-xs">
        <input type="checkbox" checked={isFilterable} onChange={(e) => setIsFilterable(e.target.checked)} /> filterable
      </label>
      {error && <p className="text-xs text-red-600">{error}</p>}
      <button type="submit" disabled={busy} className="btn-secondary">
        {busy ? "Creating…" : "Add attribute"}
      </button>
    </form>
  );
}

function AddOptionForms({ fields, onCreated }: { fields: ComposedSchema["groups"][number]["fields"]; onCreated: () => void }) {
  const optionFields = fields.filter((f) => f.dataType === "option" || f.dataType === "option_multi");
  const dependentFields = fields.filter((f) => f.dependsOn.some((d) => d.rule === "options_filtered_by"));
  if (optionFields.length === 0) return null;

  return (
    <div className="mt-3 space-y-2">
      {optionFields.map((f) => (
        <AddOptionForm
          key={f.key}
          field={f}
          // if another field depends on this one (e.g. model depends on brand),
          // let the admin optionally scope the new option under a parent option
          parentCandidates={dependentFields.length > 0 ? f.options : []}
          onCreated={onCreated}
        />
      ))}
    </div>
  );
}

function AddOptionForm({
  field,
  parentCandidates,
  onCreated,
}: {
  field: ComposedSchema["groups"][number]["fields"][number];
  parentCandidates: ComposedSchema["groups"][number]["fields"][number]["options"];
  onCreated: () => void;
}) {
  const [value, setValue] = useState("");
  const [label, setLabel] = useState("");
  const [parentOptionId, setParentOptionId] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post(`/v1/attributes/${field.id}/options`, {
        value,
        labelI18n: { en: label },
        parentOptionId: parentOptionId || null,
      });
      setValue("");
      setLabel("");
      onCreated();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create option");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="rounded border border-dashed border-slate-300 p-3">
      <p className="text-xs font-semibold text-slate-600">Add option to &ldquo;{field.label}&rdquo;</p>
      <div className="mt-2 grid grid-cols-2 gap-2">
        <input value={value} onChange={(e) => setValue(e.target.value)} placeholder="value (e.g. bmw)" className="input" required />
        <input value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Label" className="input" required />
      </div>
      {parentCandidates.length > 0 && (
        <select value={parentOptionId} onChange={(e) => setParentOptionId(e.target.value)} className="input mt-2">
          <option value="">No parent (top-level option)</option>
          {parentCandidates.map((o) => (
            <option key={o.id} value={o.id}>
              Under: {o.label}
            </option>
          ))}
        </select>
      )}
      {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
      <button type="submit" disabled={busy} className="btn-secondary mt-2">
        {busy ? "Creating…" : "Add option"}
      </button>
    </form>
  );
}

