"use client";

// Proves the golden path end-to-end from the dashboard: pick any leaf
// category, however structurally different its schema, and the SAME
// DynamicFormPreview renderer (Schema Builder's live-preview component)
// produces a real, submittable create-listing form — schema-driven, not
// screen-driven. See docs/planning/05-dynamic-schema-engine.md §9.

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/components/AuthProvider";
import { DynamicFormPreview } from "@/components/DynamicFieldPreview";
import type { CategoryTreeNode, ComposedSchema } from "@/lib/contract-types";

function flattenLeaves(nodes: CategoryTreeNode[], path: string[] = []): Array<{ id: string; label: string }> {
  return nodes.flatMap((n) => {
    const here = [...path, n.name];
    return n.isLeaf
      ? [{ id: n.id, label: here.join(" › ") }]
      : flattenLeaves(n.children, here);
  });
}

export default function NewListingPage() {
  const router = useRouter();
  const { session } = useAuth();
  const { data: tree } = useApi<CategoryTreeNode[]>("/v1/categories/tree?locale=en");
  const leaves = useMemo(() => (tree ? flattenLeaves(tree) : []), [tree]);

  const [categoryId, setCategoryId] = useState("");
  const { data: schema } = useApi<ComposedSchema>(categoryId ? `/v1/categories/${categoryId}/schema?locale=en` : null, [categoryId]);

  const [title, setTitle] = useState("");
  const [price, setPrice] = useState("");
  const [currency, setCurrency] = useState("SAR");
  const [attributes, setAttributes] = useState<Record<string, unknown>>({});
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<ApiError | Error | null>(null);

  if (!session) {
    return (
      <p className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
        Sign in (any dev identity) to create a listing.
      </p>
    );
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await api.post("/v1/listings", {
        categoryId,
        title,
        price: price ? Number(price) : undefined,
        currency,
        attributes,
      });
      router.push("/listings");
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-lg font-semibold">Create a listing</h1>
        <p className="mt-1 text-sm text-slate-600">
          The form below is generated entirely from the selected category&rsquo;s schema — the same renderer the
          Schema Builder previews with.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="grid gap-6 md:grid-cols-2">
        <div className="space-y-4 rounded-lg border border-slate-200 bg-white p-5">
          <label className="block text-sm">
            <span className="mb-1 block text-slate-600">Category</span>
            <select className="input" value={categoryId} onChange={(e) => { setCategoryId(e.target.value); setAttributes({}); }} required>
              <option value="">Select a category…</option>
              {leaves.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.label}
                </option>
              ))}
            </select>
          </label>

          <label className="block text-sm">
            <span className="mb-1 block text-slate-600">Title</span>
            <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} required />
          </label>

          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm">
              <span className="mb-1 block text-slate-600">Price</span>
              <input className="input" type="number" value={price} onChange={(e) => setPrice(e.target.value)} />
            </label>
            <label className="block text-sm">
              <span className="mb-1 block text-slate-600">Currency</span>
              <input className="input" value={currency} onChange={(e) => setCurrency(e.target.value)} />
            </label>
          </div>

          {schema && (
            <div className="border-t border-slate-100 pt-4">
              <DynamicFormPreview
                groups={schema.groups}
                values={attributes}
                onChange={(key, value) => setAttributes((prev) => ({ ...prev, [key]: value }))}
              />
            </div>
          )}

          {error && (
            <div className="rounded border border-red-200 bg-red-50 p-3 text-xs text-red-700">
              {error.message}
              {error instanceof ApiError && error.fields && (
                <ul className="mt-1 list-disc pl-4">
                  {error.fields.map((f) => (
                    <li key={f.field}>
                      {f.field}: {f.message}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          )}

          <button type="submit" disabled={submitting || !categoryId} className="btn-primary">
            {submitting ? "Creating…" : "Create draft listing"}
          </button>
        </div>
      </form>
    </div>
  );
}
