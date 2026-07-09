#!/usr/bin/env bash
# Promote a profiles row to role=leader by email.
#
# Usage:
#   # local docker-compose Postgres
#   ./scripts/promote-user-to-leader.sh xiandongyang1116@gmail.com "ning li"
#
#   # production / staging via in-cluster psql (RDS is VPC-only)
#   ./scripts/promote-user-to-leader.sh --prod xiandongyang1116@gmail.com "ning li"
#
# Env overrides:
#   PG_CONTAINER=maildesk-postgres
#   K8S_NAMESPACE=maildesk
#   DB_USER / DB_NAME (local only)

set -euo pipefail

TARGET="local"
if [[ "${1:-}" == "--prod" || "${1:-}" == "--k8s" ]]; then
  TARGET="prod"
  shift
fi

EMAIL="${1:-xiandongyang1116@gmail.com}"
DISPLAY_NAME="${2:-ning li}"
PG_CONTAINER="${PG_CONTAINER:-maildesk-postgres}"
K8S_NAMESPACE="${K8S_NAMESPACE:-maildesk}"
PROMOTE_POD="maildesk-psql-promote-$$"

cleanup_prod() {
  kubectl delete pod "$PROMOTE_POD" -n "$K8S_NAMESPACE" --ignore-not-found >/dev/null 2>&1 || true
}

run_local() {
  if ! docker ps --format '{{.Names}}' | grep -qx "$PG_CONTAINER"; then
    echo "ERROR: docker container '$PG_CONTAINER' is not running." >&2
    exit 1
  fi
  docker exec -i "$PG_CONTAINER" \
    psql -U "${DB_USER:-maildesk}" -d "${DB_NAME:-maildesk}" -v ON_ERROR_STOP=1 \
    -v "email=${EMAIL}" \
    -v "name=${DISPLAY_NAME}" \
    "$@"
}

ensure_prod_pod() {
  local api_pod
  api_pod="$(kubectl get pods -n "$K8S_NAMESPACE" -l app.kubernetes.io/component=api -o jsonpath='{.items[0].metadata.name}')"
  if [[ -z "$api_pod" ]]; then
    echo "ERROR: no maildesk-api pod in namespace $K8S_NAMESPACE" >&2
    exit 1
  fi

  DB_HOST="$(kubectl exec -n "$K8S_NAMESPACE" "$api_pod" -- printenv DB_HOST)"
  DB_PORT="$(kubectl exec -n "$K8S_NAMESPACE" "$api_pod" -- printenv DB_PORT)"
  DB_NAME="$(kubectl exec -n "$K8S_NAMESPACE" "$api_pod" -- printenv DB_NAME)"
  DB_USER="$(kubectl exec -n "$K8S_NAMESPACE" "$api_pod" -- printenv DB_USER)"

  trap cleanup_prod EXIT

  kubectl apply -f - >/dev/null <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${PROMOTE_POD}
  namespace: ${K8S_NAMESPACE}
spec:
  restartPolicy: Never
  containers:
    - name: psql
      image: postgres:16-alpine
      env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: maildesk-secrets
              key: DB_PASSWORD
      command: ["sleep", "300"]
EOF

  kubectl wait --for=condition=Ready "pod/${PROMOTE_POD}" -n "$K8S_NAMESPACE" --timeout=120s >/dev/null
}

run_prod() {
  kubectl exec -i -n "$K8S_NAMESPACE" "$PROMOTE_POD" -- \
    psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
    -v "email=${EMAIL}" \
    -v "name=${DISPLAY_NAME}" \
    "$@"
}

run_psql() {
  if [[ "$TARGET" == "prod" ]]; then
    run_prod "$@"
  else
    run_local "$@"
  fi
}

echo "==> Target=${TARGET} email=${EMAIL} display_name=${DISPLAY_NAME}"
if [[ "$TARGET" == "prod" ]]; then
  ensure_prod_pod
fi

echo "==> Looking up profile..."
run_psql <<'SQL'
SELECT id, display_name, email, role, status, feishu_operator_name
FROM profiles
WHERE email ILIKE :'email'
   OR display_name ILIKE :'name'
ORDER BY created_at;
SQL

MATCHES="$(run_psql -At <<'SQL'
SELECT count(*)
FROM profiles
WHERE email ILIKE :'email'
  AND deleted_at IS NULL;
SQL
)"
MATCHES="$(echo "$MATCHES" | tr -d '[:space:]')"

if [[ "$MATCHES" != "1" ]]; then
  echo "ERROR: expected exactly 1 active profile for email=${EMAIL}, found ${MATCHES}." >&2
  exit 1
fi

echo "==> Promoting to leader..."
run_psql <<'SQL'
UPDATE profiles
SET role = 'leader',
    updated_at = NOW()
WHERE email ILIKE :'email'
  AND deleted_at IS NULL;

SELECT id, display_name, email, role, status, feishu_operator_name, updated_at
FROM profiles
WHERE email ILIKE :'email';
SQL

echo "==> Done. Ask the user to re-login (or refresh /me) so the session picks up role=leader."
