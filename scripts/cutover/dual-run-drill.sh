#!/usr/bin/env bash
# P6-T11 — 双跑 + 切流方案演练（dry-run orchestrator）
#
# 用法：
#   cp env.example .env.cutover && 编辑
#   ./dual-run-drill.sh
#
# 退出码：0 = 全部自动检查通过；1 = 有门禁失败
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DOCS_ROOT="$(cd "$ROOT/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/.env.cutover}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*" >&2; FAILED=1; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
step() { echo; echo "==> $*"; }

FAILED=0
MANUAL_GATES=()

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE — cp env.example .env.cutover and fill values." >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a && source "$ENV_FILE" && set +a

DRY_RUN_ONLY="${DRY_RUN_ONLY:-true}"
MIGRATION_ENV="${MIGRATION_ENV:-$ROOT/../migration/.env.migration}"
NEW_API_BASE_URL="${NEW_API_BASE_URL:-}"
NEW_WEB_BASE_URL="${NEW_WEB_BASE_URL:-}"

echo "Mail Desk v2 — dual-run / cutover drill (P6-T11)"
echo "Docs root: $DOCS_ROOT"
echo "DRY_RUN_ONLY=$DRY_RUN_ONLY"

# ---------------------------------------------------------------------------
step "0/6  Prerequisites"
# ---------------------------------------------------------------------------
for cmd in psql curl python3; do
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "$cmd found"
  else
    fail "required command missing: $cmd"
  fi
done

if [[ -f "$MIGRATION_ENV" ]]; then
  pass "migration env: $MIGRATION_ENV"
else
  warn "migration env not found ($MIGRATION_ENV) — skip migrate/diff unless you set MIGRATION_ENV"
fi

if [[ -n "$NEW_API_BASE_URL" ]]; then
  pass "NEW_API_BASE_URL=$NEW_API_BASE_URL"
else
  warn "NEW_API_BASE_URL unset — skip API health checks"
fi

# ---------------------------------------------------------------------------
step "1/6  Feature parity gate (05-feature-parity.md)"
# ---------------------------------------------------------------------------
FP="$DOCS_ROOT/specs/05-feature-parity.md"
if [[ ! -f "$FP" ]]; then
  fail "missing $FP"
else
  OPEN_COUNT=$(grep -c '^\- \[ \]' "$FP" || true)
  if [[ "$OPEN_COUNT" -eq 0 ]]; then
    pass "feature-parity: 0 open [ ] items"
  else
    fail "feature-parity: $OPEN_COUNT open [ ] items — cutover blocked (see 04-phases.md)"
    grep -n '^\- \[ \]' "$FP" | head -20 >&2 || true
    if [[ "$OPEN_COUNT" -gt 20 ]]; then
      echo "  ... and $((OPEN_COUNT - 20)) more" >&2
    fi
  fi
fi

# ---------------------------------------------------------------------------
step "2/6  Data migration (optional full import)"
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN_ONLY" == "true" ]]; then
  warn "DRY_RUN_ONLY=true — skipping migrate.sh (set DRY_RUN_ONLY=false for full import drill)"
elif [[ ! -f "$MIGRATION_ENV" ]]; then
  fail "DRY_RUN_ONLY=false but MIGRATION_ENV missing"
else
  ENV_FILE="$MIGRATION_ENV" "$ROOT/../migration/migrate.sh"
  pass "migrate.sh completed"
  if [[ -f "$MIGRATION_ENV" ]]; then
    # shellcheck disable=SC1090
    set -a && source "$MIGRATION_ENV" && set +a
    ENV_FILE="$MIGRATION_ENV" "$ROOT/../migration/migrate-google-credentials.sh" || \
      warn "Google credential migration skipped or failed — users may need re-OAuth"
  fi
fi

# ---------------------------------------------------------------------------
step "3/6  Migration diff (06-testing.md §7)"
# ---------------------------------------------------------------------------
if [[ -f "$MIGRATION_ENV" ]]; then
  if ENV_FILE="$MIGRATION_ENV" "$ROOT/../migration/diff.sh"; then
    pass "diff.sh within tolerance"
  else
    fail "diff.sh exceeded tolerance — do NOT cut over"
  fi
else
  warn "skip diff.sh (no MIGRATION_ENV)"
fi

# ---------------------------------------------------------------------------
step "4/6  New stack health checks"
# ---------------------------------------------------------------------------
if [[ -n "$NEW_API_BASE_URL" ]]; then
  HEALTH_URL="${NEW_API_BASE_URL%/}/actuator/health"
  HTTP_CODE=$(curl -sf -o /dev/null -w '%{http_code}' "$HEALTH_URL" 2>/dev/null || echo "000")
  if [[ "$HTTP_CODE" == "200" ]]; then
    pass "API health $HEALTH_URL → $HTTP_CODE"
  else
    fail "API health $HEALTH_URL → HTTP $HTTP_CODE"
  fi

  PROM_URL="${NEW_API_BASE_URL%/}/actuator/prometheus"
  if curl -sf -o /dev/null "$PROM_URL" 2>/dev/null; then
    pass "Prometheus scrape endpoint reachable"
  else
    warn "Prometheus endpoint not reachable (may be disabled in profile)"
  fi
else
  warn "skip API health checks"
fi

if [[ -n "$NEW_WEB_BASE_URL" ]]; then
  WEB_CODE=$(curl -sf -o /dev/null -w '%{http_code}' "$NEW_WEB_BASE_URL" 2>/dev/null || echo "000")
  if [[ "$WEB_CODE" =~ ^(200|301|302|307|308)$ ]]; then
    pass "Web $NEW_WEB_BASE_URL → $WEB_CODE"
  else
    fail "Web $NEW_WEB_BASE_URL → HTTP $WEB_CODE"
  fi
fi

# ---------------------------------------------------------------------------
step "5/6  Manual smoke gates (record in drill sign-off)"
# ---------------------------------------------------------------------------
MANUAL_GATES+=(
  "Gmail 发信冒烟: scripts/gmail-send-smoke.md (staging OAuth)"
  "Gmail 增量同步: 工作台手动同步 + Worker 5min job 无 ERROR 日志"
  "飞书同步: POST /api/v1/sync/feishu 202 + 进度完成"
  "定时邮件: 创建 2min 后 scheduled → sent（或 failed 可解释）"
  "OAuth 登录 + Gmail 重新授权 banner 不出现（或引导正确）"
  "AI 四能力: classify / draft / check / translate 各 1 次"
)

for gate in "${MANUAL_GATES[@]}"; do
  warn "MANUAL: $gate"
done

# ---------------------------------------------------------------------------
step "6/6  Cutover drill checklist (no DNS changes)"
# ---------------------------------------------------------------------------
echo
echo "--- Cutover drill sign-off (production cutover 前人工确认) ---"
echo "[ ] 双跑 ≥14 天：旧 Vercel + 新 K8s 并行，业务仍走旧系统"
echo "[ ] 预发全量 migrate + diff.sh 绿"
echo "[ ] 一切流窗口：低峰 + 公告禁写 10 分钟"
echo "[ ] 切流顺序: 1) 停旧写 2) 最终 diff 3) DNS/API Ingress 4) 新前端 Vercel 5) 冒烟"
echo "[ ] 切流后 30min: diff.sh + Gmail sync + 发信 + 告警静默"
echo "[ ] 回滚预案已读: scripts/cutover/rollback-runbook.md"
echo "[ ] On-call 与业务方确认联系人"
echo
echo "Full procedure: scripts/cutover/cutover-runbook.md"
echo "Rollback:       scripts/cutover/rollback-runbook.md"

if [[ "${FAILED:-0}" -ne 0 ]]; then
  echo
  echo -e "${RED}Drill FAILED — fix blockers before cutover.${NC}" >&2
  exit 1
fi

echo
echo -e "${GREEN}Automated drill checks PASSED.${NC} Complete manual gates above before cutover."
exit 0
