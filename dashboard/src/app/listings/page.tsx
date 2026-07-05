"use client";

import Link from "next/link";
import { useState } from "react";
import { useApi } from "@/lib/useApi";
import { api, ApiError } from "@/lib/api";
import { useAuth } from "@/components/AuthProvider";
import type { Listing } from "@/lib/contract-types";

const STATUS_COLORS: Record<string, string> = {
  draft: "bg-slate-100 text-slate-700",
  pending_review: "bg-amber-100 text-amber-800",
  published: "bg-green-100 text-green-800",
  rejected: "bg-red-100 text-red-800",
  archived: "bg-slate-100 text-slate-500",
  sold: "bg-blue-100 text-blue-800",
};

// Transitions a caller with no special privilege can make on their own listing.
const OWNER_ACTIONS: Record<string, { to: string; label: string }[]> = {
  draft: [{ to: "pending_review", label: "Submit for review" }],
  pending_review: [{ to: "draft", label: "Withdraw" }],
  published: [
    { to: "archived", label: "Archive" },
    { to: "sold", label: "Mark sold" },
  ],
  rejected: [{ to: "draft", label: "Move back to draft" }],
  archived: [{ to: "draft", label: "Relist (move to draft)" }],
};

export default function ListingsPage() {
  const { session } = useAuth();
  const isModerator = session?.appRole === "moderator" || session?.appRole === "admin" || session?.appRole === "super_admin";

  // The URL text alone doesn't vary by who's asking ("owner=me" resolves
  // server-side from the bearer token), so useApi's default "only refetch
  // when the path string changes" misses identity switches — surfaced by
  // switching dev identities in the browser and seeing stale data. Passing
  // the session's sub as an explicit dep forces a refetch on every switch.
  const { data: mine, loading: loadingMine, reload: reloadMine } = useApi<Listing[]>(
    session ? "/v1/listings?owner=me" : null,
    [session?.sub],
  );
  const { data: queue, loading: loadingQueue, reload: reloadQueue } = useApi<Listing[]>(
    isModerator ? "/v1/listings?status=pending_review" : null,
    [session?.sub],
  );

  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function transition(id: string, status: string) {
    setBusyId(id);
    setError(null);
    try {
      await api.patch(`/v1/listings/${id}`, { status });
      reloadMine();
      reloadQueue();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to update listing");
    } finally {
      setBusyId(null);
    }
  }

  if (!session) {
    return (
      <p className="rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
        Sign in (any dev identity) to see your listings.
      </p>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-lg font-semibold">Listings</h1>
          <p className="mt-1 text-sm text-slate-600">Create, submit for review, and (if you&rsquo;re a moderator) approve or reject.</p>
        </div>
        <Link href="/listings/new" className="btn-primary">
          + New listing
        </Link>
      </div>

      {error && <p className="rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>}

      {isModerator && (
        <Section title={`Moderation queue (pending_review)${queue ? ` — ${queue.length}` : ""}`}>
          {loadingQueue && <p className="text-sm text-slate-500">Loading…</p>}
          {queue && queue.length === 0 && <p className="text-sm text-slate-500">Nothing waiting for review.</p>}
          {queue?.map((l) => (
            <ListingRow key={l.id} listing={l} busy={busyId === l.id}>
              <button onClick={() => transition(l.id, "published")} disabled={busyId === l.id} className="btn-primary">
                Approve
              </button>
              <button onClick={() => transition(l.id, "rejected")} disabled={busyId === l.id} className="btn-secondary">
                Reject
              </button>
            </ListingRow>
          ))}
        </Section>
      )}

      <Section title="My listings">
        {loadingMine && <p className="text-sm text-slate-500">Loading…</p>}
        {mine && mine.length === 0 && (
          <p className="text-sm text-slate-500">
            No listings yet —{" "}
            <Link href="/listings/new" className="underline">
              create one
            </Link>
            .
          </p>
        )}
        {mine?.map((l) => (
          <ListingRow key={l.id} listing={l} busy={busyId === l.id}>
            {(OWNER_ACTIONS[l.status] ?? []).map((action) => (
              <button key={action.to} onClick={() => transition(l.id, action.to)} disabled={busyId === l.id} className="btn-secondary">
                {action.label}
              </button>
            ))}
          </ListingRow>
        ))}
      </Section>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h2 className="mb-3 text-sm font-semibold text-slate-800">{title}</h2>
      <div className="space-y-2">{children}</div>
    </div>
  );
}

function ListingRow({ listing, busy, children }: { listing: Listing; busy: boolean; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-lg border border-slate-200 bg-white p-4">
      <div>
        <p className="text-sm font-medium text-slate-900">{listing.title}</p>
        <p className="mt-0.5 text-xs text-slate-500">
          {listing.price ? `${listing.price} ${listing.currency ?? ""}` : "No price"} ·{" "}
          <span className={`rounded-full px-1.5 py-0.5 font-medium ${STATUS_COLORS[listing.status] ?? ""}`}>{listing.status}</span>
        </p>
      </div>
      <div className={`flex gap-2 ${busy ? "opacity-50" : ""}`}>{children}</div>
    </div>
  );
}
