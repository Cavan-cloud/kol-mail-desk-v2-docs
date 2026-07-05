#!/usr/bin/env bash
# Diff report: legacy Supabase vs new PG (P6-T10). Exit 1 if any check fails tolerance.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/.env.migration}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

: "${SOURCE_DATABASE_URL:?}"
: "${TARGET_DATABASE_URL:?}"
: "${DEFAULT_TENANT_ID:=00000000-0000-0000-0000-000000000001}"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

psql "$SOURCE_DATABASE_URL" -v ON_ERROR_STOP=1 -At -F'|' -f "$ROOT/sql/diff-source.sql" > "$TMP.source"
psql "$TARGET_DATABASE_URL" -v ON_ERROR_STOP=1 -At -F'|' \
  -v tenant_id="$DEFAULT_TENANT_ID" -f "$ROOT/sql/diff-target.sql" > "$TMP.target"

python3 - "$TMP.source" "$TMP.target" "$ROOT" <<'PY'
import os
import subprocess
import sys
from pathlib import Path

source = {}
target = {}
for path, store in [(sys.argv[1], source), (sys.argv[2], target)]:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            key, val = line.split("|", 1)
            store[key] = int(val)

# metric -> tolerance (from specs/06-testing.md)
tolerances = {
    "kols_total": 1,
    "emails_total": 5,
    "feishu_outreach_not_null": 2,
    "profiles_total": 0,
}

def tolerance_for(key: str) -> int:
    if key.startswith("stage:"):
        return 2
    if key.startswith("owner:"):
        return 1
    return tolerances.get(key, 0)

failed = False
print(f"{'metric':<40} {'source':>8} {'target':>8} {'delta':>8} {'tol':>6} {'ok':>4}")
print("-" * 78)

all_keys = sorted(set(source) | set(target))
for key in all_keys:
    s = source.get(key, 0)
    t = target.get(key, 0)
    delta = abs(s - t)
    base = key.split(":")[0] if ":" in key else key
    tol = tolerance_for(key)
    ok = delta <= tol
    if not ok:
        failed = True
    print(f"{key:<40} {s:>8} {t:>8} {delta:>8} {tol:>6} {'OK' if ok else 'FAIL':>4}")

if failed:
    print("\nDiff tolerance exceeded — do NOT cut over.", file=sys.stderr)
    sys.exit(1)

# Latest email per KOL — zero tolerance (specs/06-testing.md)
sql_dir = Path(sys.argv[3]) / "sql"
tenant = os.environ.get("DEFAULT_TENANT_ID", "00000000-0000-0000-0000-000000000001")
src_lines = subprocess.check_output(
    ["psql", os.environ["SOURCE_DATABASE_URL"], "-v", "ON_ERROR_STOP=1", "-At", "-f",
     str(sql_dir / "diff-kol-latest-source.sql")],
    text=True,
).strip().splitlines()
tgt_lines = subprocess.check_output(
    ["psql", os.environ["TARGET_DATABASE_URL"], "-v", "ON_ERROR_STOP=1", "-At",
     "-v", f"tenant_id={tenant}", "-f",
     str(sql_dir / "diff-kol-latest-target.sql")],
    text=True,
).strip().splitlines()

src_set = set(src_lines)
tgt_set = set(tgt_lines)
if src_set != tgt_set:
    only_src = src_set - tgt_set
    only_tgt = tgt_set - src_set
    print("\nKOL latest gmail_message_id mismatch (zero tolerance):", file=sys.stderr)
    if only_src:
        print(f"  only in source: {len(only_src)}", file=sys.stderr)
    if only_tgt:
        print(f"  only in target: {len(only_tgt)}", file=sys.stderr)
    sys.exit(1)

print("\nAll diff checks within tolerance (including KOL latest email IDs).")
PY

