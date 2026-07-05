"use client";

import { useState } from "react";
import { CategoryTree } from "@/components/CategoryTree";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import type { CategoryTreeNode } from "@/lib/contract-types";
import { useAuth } from "@/components/AuthProvider";

export default function CatalogPage() {
  const { data: tree, loading, error, reload } = useApi<CategoryTreeNode[]>("/v1/categories/tree?locale=en");
  const { session } = useAuth();
  const canWrite = session?.appRole === "catalog_editor" || session?.appRole === "admin" || session?.appRole === "super_admin";

  return (
    <div className="grid gap-6 md:grid-cols-[2fr_1fr]">
      <div className="rounded-lg border border-slate-200 bg-white p-5">
        <h1 className="text-lg font-semibold">Category tree ⭐</h1>
        <p className="mt-1 text-sm text-slate-600">
          The Dynamic Category &amp; Attribute Engine — click a category to view/edit its schema.
        </p>
        <div className="mt-4">
          {loading && <p className="text-sm text-slate-500">Loading…</p>}
          {error && <p className="text-sm text-red-600">{error.message}</p>}
          {tree && <CategoryTree nodes={tree} />}
        </div>
      </div>

      <div className="space-y-4">
        {canWrite ? (
          <NewCategoryForm onCreated={reload} />
        ) : (
          <div className="rounded-lg border border-slate-200 bg-white p-5 text-sm text-slate-600">
            Sign in as <code>catalog_editor</code> or <code>admin</code> to create categories.
          </div>
        )}
      </div>
    </div>
  );
}

function NewCategoryForm({ onCreated }: { onCreated: () => void }) {
  const [slug, setSlug] = useState("");
  const [nameEn, setNameEn] = useState("");
  const [nameAr, setNameAr] = useState("");
  const [isLeaf, setIsLeaf] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api.post("/v1/categories", {
        parentId: null,
        slug,
        nameI18n: { en: nameEn, ...(nameAr ? { ar: nameAr } : {}) },
        isLeaf,
      });
      setSlug("");
      setNameEn("");
      setNameAr("");
      onCreated();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create category");
    } finally {
      setBusy(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="rounded-lg border border-slate-200 bg-white p-5 space-y-3">
      <h2 className="font-semibold text-sm">New top-level category</h2>
      <Field label="Slug (kebab-case)">
        <input value={slug} onChange={(e) => setSlug(e.target.value)} placeholder="e.g. sports" className="input" required />
      </Field>
      <Field label="Name (English)">
        <input value={nameEn} onChange={(e) => setNameEn(e.target.value)} className="input" required />
      </Field>
      <Field label="Name (Arabic, optional)">
        <input value={nameAr} onChange={(e) => setNameAr(e.target.value)} className="input" dir="rtl" />
      </Field>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" checked={isLeaf} onChange={(e) => setIsLeaf(e.target.checked)} />
        Leaf category (listings can be posted directly here)
      </label>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button type="submit" disabled={busy} className="btn-primary">
        {busy ? "Creating…" : "Create category"}
      </button>
    </form>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block text-sm">
      <span className="mb-1 block text-slate-600">{label}</span>
      {children}
    </label>
  );
}
