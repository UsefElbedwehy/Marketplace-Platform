#!/usr/bin/env bash
# Applies backend/supabase/migrations/*.sql then backend/supabase/seed/*.sql, in filename
# order, to a local Postgres database — the same order `supabase db reset` would apply
# them via config.toml's db.migrations / db.seed.sql_paths, but runnable without Docker
# against a plain Homebrew Postgres. See backend/README.md.
set -euo pipefail

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
DB_NAME="${1:-marketplace_platform_dev}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

dropdb --if-exists "$DB_NAME"
createdb "$DB_NAME"

for f in "$REPO_ROOT"/backend/supabase/migrations/*.sql; do
  echo "==> migration: $(basename "$f")"
  psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -f "$f"
done

shopt -s nullglob
seed_files=("$REPO_ROOT"/backend/supabase/seed/*.sql)
if [ "${#seed_files[@]}" -gt 0 ]; then
  for f in "${seed_files[@]}"; do
    echo "==> seed: $(basename "$f")"
    psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -f "$f"
  done
fi

echo "==> done. Database '$DB_NAME' is ready."
