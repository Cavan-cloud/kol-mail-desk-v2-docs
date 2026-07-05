#!/usr/bin/env bash
# Migrate legacy Supabase public schema → maildesk v2 PostgreSQL (P6-T10).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/.env.migration}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — cp env.example .env.migration and fill URLs." >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

: "${SOURCE_DATABASE_URL:?Set SOURCE_DATABASE_URL}"
: "${TARGET_DATABASE_URL:?Set TARGET_DATABASE_URL}"
: "${DEFAULT_TENANT_ID:=00000000-0000-0000-0000-000000000001}"

run_sql() {
  local file="$1"
  echo "==> $(basename "$file")"
  psql "$TARGET_DATABASE_URL" -v ON_ERROR_STOP=1 \
    -v source_dsn="$SOURCE_DATABASE_URL" \
    -v tenant_id="$DEFAULT_TENANT_ID" \
    -f "$file"
}

for f in "$ROOT"/sql/[0-9][0-9]_*.sql; do
  [[ -f "$f" ]] || continue
  run_sql "$f"
done

echo "Migration SQL complete. Run ./diff.sh before cutover."
