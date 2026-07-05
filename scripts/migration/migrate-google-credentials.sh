#!/usr/bin/env bash
# Encrypt legacy Supabase Google tokens into integration_credentials (P6-T10).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/.env.migration}"
BACKEND_ROOT="$(cd "$ROOT/../../../kol-mail-desk-v2-backend" && pwd)"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

: "${TARGET_DATABASE_URL:?Set TARGET_DATABASE_URL (target / maildesk v2)}"
: "${SOURCE_DATABASE_URL:?Set SOURCE_DATABASE_URL (legacy Supabase)}"
: "${TOKEN_ENCRYPTION_KEY:?Set TOKEN_ENCRYPTION_KEY — same as production target app}"

export MIGRATION_SOURCE_JDBC_URL="$SOURCE_DATABASE_URL"
export MIGRATION_SOURCE_USERNAME="${MIGRATION_SOURCE_USERNAME:-postgres}"
export MIGRATION_SOURCE_PASSWORD="${MIGRATION_SOURCE_PASSWORD:-}"

# Map TARGET_DATABASE_URL → Spring datasource env (same as .env.example)
if [[ "$TARGET_DATABASE_URL" =~ postgres(ql)?://([^:]+):([^@]+)@([^:/]+):?([0-9]*)/([^?]+) ]]; then
  export DB_USER="${BASH_REMATCH[2]}"
  export DB_PASSWORD="${BASH_REMATCH[3]}"
  export DB_HOST="${BASH_REMATCH[4]}"
  export DB_PORT="${BASH_REMATCH[5]:-5432}"
  export DB_NAME="${BASH_REMATCH[6]}"
else
  echo "Cannot parse TARGET_DATABASE_URL — set DB_HOST/DB_USER/DB_PASSWORD/DB_NAME manually." >&2
  exit 1
fi

export REDIS_HOST="${REDIS_HOST:-localhost}"
export REDIS_PORT="${REDIS_PORT:-6379}"

cd "$BACKEND_ROOT"
mvn -q -pl maildesk-worker -am spring-boot:run \
  -Dspring-boot.run.profiles=migration \
  -Dspring-boot.run.jvmArguments="-Dmaildesk.migration.source-jdbc-url=${MIGRATION_SOURCE_JDBC_URL}"
