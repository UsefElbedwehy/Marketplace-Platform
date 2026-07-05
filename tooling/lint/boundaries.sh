#!/usr/bin/env bash
# Executable architecture-boundary checks. These make the guarantees in
# docs/planning/01-system-architecture.md §4 and ADR-0014 real rather than
# aspirational — a violation fails CI, not just code review.
#
# Rules enforced (checked across ios/Packages and ios/App):
#   1. No `import Supabase` outside ios/Packages/Networking.
#   2. No raw color/font literals outside ios/Packages/DesignSystem.
#   3. No Features/<X> importing Features/<Y> directly.
#
# Each check no-ops cleanly ("skip") when the directory it inspects doesn't
# exist yet (true for most of these in Phase 0, before any Swift code lands).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

overall_fail=0

# --- 1. Supabase import isolation -------------------------------------------
check_supabase_isolation() {
  local desc="No 'import Supabase' outside ios/Packages/Networking"
  local roots=("ios/Packages" "ios/App")
  local existing_roots=()
  for root in "${roots[@]}"; do
    [ -d "$root" ] && existing_roots+=("$root")
  done

  if [ "${#existing_roots[@]}" -eq 0 ]; then
    echo "skip  $desc (no ios/Packages or ios/App yet)"
    return
  fi

  local matches
  matches=$(grep -rnE '^\s*import\s+Supabase\b' "${existing_roots[@]}" \
    --include='*.swift' \
    --exclude-dir=Networking \
    --exclude-dir=.build \
    --exclude-dir=.swiftpm \
    2>/dev/null || true)

  if [ -n "$matches" ]; then
    echo "FAIL  $desc"
    echo "$matches" | sed 's/^/        /'
    overall_fail=1
  else
    echo "ok    $desc"
  fi
}

# --- 2. Raw color/font literals outside DesignSystem ------------------------
check_design_system_isolation() {
  local desc="No raw Color()/UIColor()/Font.system() literals outside ios/Packages/DesignSystem"
  # App (the composition root) is free to depend on anything, but must still
  # consume DesignSystem's tokens rather than its own literals — the "App may
  # depend on everything" rule in 01-system-architecture.md §4 is about the
  # dependency graph, not a license to bypass the theme engine.
  local roots=("ios/Packages" "ios/App")
  local existing_roots=()
  for root in "${roots[@]}"; do
    [ -d "$root" ] && existing_roots+=("$root")
  done

  if [ "${#existing_roots[@]}" -eq 0 ]; then
    echo "skip  $desc (no ios/Packages or ios/App yet)"
    return
  fi

  local matches
  matches=$(grep -rnE '(Color\((red|hex)|UIColor\(red|Font\.system\(size)' "${existing_roots[@]}" \
    --include='*.swift' \
    --exclude-dir=DesignSystem \
    --exclude-dir=.build \
    --exclude-dir=.swiftpm \
    2>/dev/null || true)

  if [ -n "$matches" ]; then
    echo "FAIL  $desc"
    echo "$matches" | sed 's/^/        /'
    overall_fail=1
  else
    echo "ok    $desc"
  fi
}

# --- 3. No Feature -> Feature imports ---------------------------------------
check_feature_isolation() {
  local desc="No Features/<X> importing another Features/<Y> module"
  local root="ios/Packages/Features"

  if [ ! -d "$root" ]; then
    echo "skip  $desc (no $root yet)"
    return
  fi

  local feature_names=()
  for dir in "$root"/*/; do
    [ -d "$dir" ] || continue
    feature_names+=("$(basename "$dir")")
  done

  if [ "${#feature_names[@]}" -eq 0 ]; then
    echo "skip  $desc (no feature modules yet)"
    return
  fi

  local violation_found=0
  for feature in "${feature_names[@]}"; do
    for other in "${feature_names[@]}"; do
      [ "$feature" = "$other" ] && continue
      local matches
      matches=$(grep -rnE "^\s*import\s+${other}\b" "$root/$feature" --include='*.swift' --exclude-dir=.build --exclude-dir=.swiftpm 2>/dev/null || true)
      if [ -n "$matches" ]; then
        echo "FAIL  $desc"
        echo "        $feature imports $other:"
        echo "$matches" | sed 's/^/          /'
        violation_found=1
        overall_fail=1
      fi
    done
  done

  if [ "$violation_found" -eq 0 ]; then
    echo "ok    $desc"
  fi
}

check_supabase_isolation
check_design_system_isolation
check_feature_isolation

if [ "$overall_fail" -ne 0 ]; then
  echo ""
  echo "Architecture boundary check(s) failed."
  exit 1
fi

echo ""
echo "All architecture boundary checks passed."
