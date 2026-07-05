"use client";

import { useCallback, useEffect, useState } from "react";
import { api, ApiError } from "./api";

/** Fetches `path` on mount and whenever `deps` change; `reload()` re-fetches on demand. */
export function useApi<T>(path: string | null, deps: unknown[] = []) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(path !== null);
  const [error, setError] = useState<ApiError | Error | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  const reload = useCallback(() => setReloadKey((k) => k + 1), []);

  useEffect(() => {
    // No path (yet) — nothing to fetch, and `loading`'s initializer already
    // reflects that on first render, so there's no setState to make here.
    if (!path) return;

    let cancelled = false;
    // react-hooks/set-state-in-effect flags this, but "reset loading/error
    // state right before kicking off the fetch that will resolve them" is
    // exactly what this effect exists to do — the standard fetch-in-effect
    // pattern, not the "derive state from props" anti-pattern the rule
    // targets. Suppressed deliberately, not overlooked.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setLoading(true);
    setError(null);
    api
      .get<T>(path)
      .then((result) => {
        if (!cancelled) setData(result);
      })
      .catch((err) => {
        if (!cancelled) setError(err instanceof Error ? err : new Error(String(err)));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
    // Collapsed to a single stable key instead of `[path, reloadKey, ...deps]`:
    // a spread makes the effect's dependency array length vary with however
    // many extra deps a given call site passes, which trips React's "array
    // size must stay constant across renders" check the moment two call
    // sites (or two states of the same one) pass different-length `deps`.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [path, reloadKey, JSON.stringify(deps)]);

  return { data, loading, error, reload };
}
