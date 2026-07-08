#!/usr/bin/env bash
# Dry-run or apply cleanup for gmail duplicate KOL rows.
#
# Requires: psql, DATABASE_URL (postgres connection string)
#
# Examples:
#   export DATABASE_URL='postgresql://maildesk:***@host:5432/maildesk'
#   ./scripts/cleanup-gmail-duplicate-kols.sh           # preview
#   ./scripts/cleanup-gmail-duplicate-kols.sh --apply   # execute

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL="${ROOT}/scripts/cleanup-gmail-duplicate-kols.sql"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "ERROR: set DATABASE_URL before running (postgres connection string)." >&2
  exit 1
fi

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then
  APPLY=1
  echo "Mode: APPLY (will mutate data)"
else
  echo "Mode: dry-run (preview only). Pass --apply to execute."
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -v APPLY="${APPLY}" -f "$SQL"
