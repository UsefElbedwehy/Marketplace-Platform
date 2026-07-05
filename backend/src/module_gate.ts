// Feature-flag gating for the Development Schema's `modules` map (ADR-0008 —
// "capability flags mount a module/tab, expose endpoints"). Phase 6 is the
// first place any endpoint actually enforces these against the active
// config; earlier modules (search, moderation, ...) aren't gated yet — a
// pre-existing gap, not introduced here. This helper is meant to be reused
// as those get gated too.

import type { ConfigBundle } from "./config_service.ts";
import { AppError } from "./errors.ts";

export function isModuleEnabled(config: ConfigBundle, moduleKey: string): boolean {
  const modules = config.document?.modules as Record<string, boolean> | undefined;
  return modules?.[moduleKey] === true;
}

// A disabled module 404s rather than 403s — from the caller's point of view
// a feature this deployment never enabled shouldn't be distinguishable from
// one that doesn't exist.
export function requireModuleEnabled(config: ConfigBundle, moduleKey: string): void {
  if (!isModuleEnabled(config, moduleKey)) {
    throw new AppError(404, "not_found", `This feature ("${moduleKey}") is not enabled for this client.`);
  }
}
