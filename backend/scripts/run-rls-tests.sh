#!/usr/bin/env bash
# Resets a DEDICATED test database (never the dev one), applies migrations +
# seed, then runs the RLS/trigger test suite in backend/tests/sql/*.sql in
# order. Exits non-zero if any assertion failed (999_report.sql raises).
set -euo pipefail

export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
DB_NAME="marketplace_platform_test"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

"$REPO_ROOT/backend/scripts/local-db-reset.sh" "$DB_NAME" > /dev/null

for f in "$REPO_ROOT"/backend/tests/sql/*.sql; do
  echo "==> test file: $(basename "$f")"
  psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -f "$f"
done
