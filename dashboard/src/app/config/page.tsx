"use client";

import { useEffect, useState } from "react";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/components/AuthProvider";
import type { RuntimeConfig } from "@marketplace-platform/contract-types";

export default function ConfigStudioPage() {
  const { data, loading, error, reload } = useApi<RuntimeConfig>("/v1/config");
  const { session } = useAuth();
  const canWrite = session?.appRole === "admin" || session?.appRole === "super_admin";
  const [draft, setDraft] = useState<RuntimeConfig | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    // Re-initializes the editable draft whenever a fresh fetch (initial load
    // or reload() after publish) lands — an intentional "sync local editable
    // copy from an external source" effect, not the derive-during-render
    // anti-pattern react-hooks/set-state-in-effect targets.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (data) setDraft(structuredClone(data));
  }, [data]);

  if (loading) return <p className="text-sm text-slate-500">Loading…</p>;
  if (error) return <p className="text-sm text-red-600">{(error as Error).message}</p>;
  if (!draft) return null;

  async function publish() {
    if (!draft) return;
    setSaving(true);
    setSaveError(null);
    setSaved(false);
    try {
      await api.patch("/v1/config", draft);
      setSaved(true);
      reload();
    } catch (err) {
      setSaveError(err instanceof ApiError ? err.message : "Failed to publish");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-lg font-semibold">Config Studio</h1>
        <p className="mt-1 text-sm text-slate-600">
          Runtime Development Schema — locales, currencies, modules, providers, flags. Publishing bumps the version
          and every client refreshes via ETag ({data?.clientId ? `client: ${data.clientId}` : ""}).
        </p>
      </div>

      {!canWrite && (
        <p className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
          Sign in as <code>admin</code> to publish changes. You can still view the current config.
        </p>
      )}

      <div className="grid gap-6 md:grid-cols-2">
        <div className="space-y-4">
          <Section title="Locales & currency">
            <Field label="Default locale">
              <select
                className="input"
                value={draft.locales.default}
                disabled={!canWrite}
                onChange={(e) => setDraft({ ...draft, locales: { ...draft.locales, default: e.target.value } })}
              >
                {draft.locales.supported.map((l) => (
                  <option key={l} value={l}>
                    {l}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Default currency">
              <select
                className="input"
                value={draft.currencies.default}
                disabled={!canWrite}
                onChange={(e) => setDraft({ ...draft, currencies: { ...draft.currencies, default: e.target.value } })}
              >
                {draft.currencies.supported.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </Field>
          </Section>

          <Section title="Modules (capability flags)">
            <div className="grid grid-cols-2 gap-2">
              {Object.entries(draft.modules).map(([key, enabled]) => (
                <label key={key} className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={Boolean(enabled)}
                    disabled={!canWrite}
                    onChange={(e) => setDraft({ ...draft, modules: { ...draft.modules, [key]: e.target.checked } })}
                  />
                  {key}
                </label>
              ))}
            </div>
          </Section>

          <Section title="Support">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={draft.support.chatEnabled ?? false}
                disabled={!canWrite}
                onChange={(e) => setDraft({ ...draft, support: { ...draft.support, chatEnabled: e.target.checked } })}
              />
              Support chat enabled
            </label>
          </Section>

          {canWrite && (
            <div className="flex items-center gap-3">
              <button onClick={publish} disabled={saving} className="btn-primary">
                {saving ? "Publishing…" : "Publish changes"}
              </button>
              {saved && <span className="text-sm text-green-700">Published — version bumped.</span>}
              {saveError && <span className="text-sm text-red-600">{saveError}</span>}
            </div>
          )}
        </div>

        <Section title="Raw document (read-only)">
          <pre className="max-h-[32rem] overflow-auto rounded bg-slate-900 p-3 text-xs text-slate-100">
            {JSON.stringify(draft, null, 2)}
          </pre>
        </Section>
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

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="mb-3 block text-sm">
      <span className="mb-1 block text-slate-600">{label}</span>
      {children}
    </label>
  );
}
