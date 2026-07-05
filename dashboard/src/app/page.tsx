"use client";

import Link from "next/link";
import { useAuth } from "@/components/AuthProvider";

export default function HomePage() {
  const { session } = useAuth();

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold">White-Label Marketplace Platform — Admin</h1>
        <p className="mt-2 text-slate-600">
          The control room and source of truth for marketplace structure — pick a dev identity above, then manage
          categories/attributes, runtime configuration, and theme tokens below.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <Link href="/catalog" className="rounded-lg border border-slate-200 bg-white p-5 hover:border-slate-400">
          <h2 className="font-semibold">Schema Builder</h2>
          <p className="mt-1 text-sm text-slate-600">
            Create categories, attribute groups, attributes, and options — the Dynamic Category &amp; Attribute
            Engine.
          </p>
        </Link>
        <Link href="/listings" className="rounded-lg border border-slate-200 bg-white p-5 hover:border-slate-400">
          <h2 className="font-semibold">Listings</h2>
          <p className="mt-1 text-sm text-slate-600">
            Create a listing via the same schema-driven form, submit it for review, and moderate the queue.
          </p>
        </Link>
        <Link href="/config" className="rounded-lg border border-slate-200 bg-white p-5 hover:border-slate-400">
          <h2 className="font-semibold">Config Studio</h2>
          <p className="mt-1 text-sm text-slate-600">
            Locales, currencies, modules, provider selection, feature flags — publish changes live.
          </p>
        </Link>
        <Link href="/theme" className="rounded-lg border border-slate-200 bg-white p-5 hover:border-slate-400">
          <h2 className="font-semibold">Theme Studio</h2>
          <p className="mt-1 text-sm text-slate-600">Semantic color tokens with a live component preview.</p>
        </Link>
      </div>

      <div className="rounded-lg border border-slate-200 bg-white p-5 text-sm">
        <h3 className="font-semibold">Session</h3>
        {session ? (
          <dl className="mt-2 grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-slate-700">
            <dt className="text-slate-500">Signed in as</dt>
            <dd>{session.displayName}</dd>
            <dt className="text-slate-500">app_role</dt>
            <dd>{session.appRole}</dd>
            <dt className="text-slate-500">tenant_id</dt>
            <dd className="font-mono text-xs">{session.tenantId}</dd>
          </dl>
        ) : (
          <p className="mt-2 text-slate-600">
            Signed out — browsing as <code>anon</code>. Writes require picking a dev identity above (
            <code>catalog_editor</code> or <code>admin</code> for the Schema/Config/Theme Studios).
          </p>
        )}
      </div>
    </div>
  );
}
