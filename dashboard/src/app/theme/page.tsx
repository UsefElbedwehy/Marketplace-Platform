"use client";

import { useEffect, useState } from "react";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/components/AuthProvider";
import type { ThemeTokens } from "@marketplace-platform/contract-types";

type SemanticColorSet = ThemeTokens["colors"]["light"];

const PREVIEW_TOKENS = ["primary", "secondary", "accent", "background", "surface", "textPrimary", "danger", "success", "border"] as const satisfies readonly (keyof SemanticColorSet)[];

export default function ThemeStudioPage() {
  const { data, loading, error, reload } = useApi<ThemeTokens>("/v1/theme");
  const { session } = useAuth();
  const canWrite = session?.appRole === "admin" || session?.appRole === "super_admin";
  const [draft, setDraft] = useState<ThemeTokens | null>(null);
  const [scheme, setScheme] = useState<"light" | "dark">("light");
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    // See the identical comment in app/config/page.tsx — intentional sync of
    // the editable draft from a freshly (re)fetched source, not the
    // derive-during-render pattern react-hooks/set-state-in-effect targets.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (data) setDraft(structuredClone(data));
  }, [data]);

  if (loading) return <p className="text-sm text-slate-500">Loading…</p>;
  if (error) return <p className="text-sm text-red-600">{(error as Error).message}</p>;
  if (!draft) return null;

  const colors = draft.colors[scheme];

  function setColor(token: keyof SemanticColorSet, value: string) {
    setDraft((prev) => {
      if (!prev) return prev;
      return { ...prev, colors: { ...prev.colors, [scheme]: { ...prev.colors[scheme], [token]: value } } };
    });
  }

  async function publish() {
    if (!draft) return;
    setSaving(true);
    setSaveError(null);
    setSaved(false);
    try {
      await api.patch("/v1/theme", draft);
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-semibold">Theme Studio</h1>
          <p className="mt-1 text-sm text-slate-600">
            Semantic tokens — change the theme, the whole app re-skins with no code change (ADR-0005).
          </p>
        </div>
        <div className="flex rounded border border-slate-300 text-sm">
          <button onClick={() => setScheme("light")} className={`px-3 py-1 ${scheme === "light" ? "bg-slate-900 text-white" : ""}`}>
            Light
          </button>
          <button onClick={() => setScheme("dark")} className={`px-3 py-1 ${scheme === "dark" ? "bg-slate-900 text-white" : ""}`}>
            Dark
          </button>
        </div>
      </div>

      {!canWrite && (
        <p className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
          Sign in as <code>admin</code> to publish changes. You can still view/preview the current theme.
        </p>
      )}

      <div className="grid gap-6 md:grid-cols-2">
        <div className="rounded-lg border border-slate-200 bg-white p-5">
          <h2 className="mb-3 text-sm font-semibold text-slate-800">Semantic tokens ({scheme})</h2>
          <div className="space-y-2">
            {PREVIEW_TOKENS.map((token) => (
              <label key={token} className="flex items-center justify-between gap-3 text-sm">
                <span className="text-slate-600">{token}</span>
                <span className="flex items-center gap-2">
                  <input
                    type="color"
                    value={colors[token]}
                    disabled={!canWrite}
                    onChange={(e) => setColor(token, e.target.value)}
                    className="h-7 w-10 cursor-pointer rounded border border-slate-300"
                  />
                  <code className="w-20 text-xs text-slate-500">{colors[token]}</code>
                </span>
              </label>
            ))}
          </div>

          {canWrite && (
            <div className="mt-4 flex items-center gap-3">
              <button onClick={publish} disabled={saving} className="btn-primary">
                {saving ? "Publishing…" : "Publish theme"}
              </button>
              {saved && <span className="text-sm text-green-700">Published — version bumped.</span>}
              {saveError && <span className="text-sm text-red-600">{saveError}</span>}
            </div>
          )}
        </div>

        <LivePreview colors={colors} />
      </div>
    </div>
  );
}

function LivePreview({ colors }: { colors: SemanticColorSet }) {
  return (
    <div
      className="rounded-lg border p-6"
      style={{ background: colors.background, borderColor: colors.border, color: colors.textPrimary }}
    >
      <h2 className="mb-4 text-sm font-semibold" style={{ color: colors.textPrimary }}>
        Live preview
      </h2>
      <div className="rounded-lg p-4" style={{ background: colors.surface, border: `1px solid ${colors.border}` }}>
        <p className="mb-1 text-sm font-semibold" style={{ color: colors.textPrimary }}>
          2019 BMW X5
        </p>
        <p className="mb-3 text-xs" style={{ color: colors.textSecondary ?? colors.textPrimary }}>
          84,000 km · Automatic · Used
        </p>
        <div className="flex items-center gap-2">
          <button className="rounded px-3 py-1.5 text-sm font-medium text-white" style={{ background: colors.primary }}>
            Contact seller
          </button>
          <button
            className="rounded px-3 py-1.5 text-sm font-medium"
            style={{ background: colors.secondary, color: colors.background }}
          >
            Save
          </button>
          <span className="rounded-full px-2 py-0.5 text-xs font-medium text-white" style={{ background: colors.danger }}>
            Sold
          </span>
          <span className="rounded-full px-2 py-0.5 text-xs font-medium text-white" style={{ background: colors.success }}>
            Verified
          </span>
        </div>
      </div>
    </div>
  );
}
