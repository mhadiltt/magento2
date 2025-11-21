kk#!/usr/bin/env bash
#
# scripts/magento-fix-perms.sh
#
# Usage:
#   ./scripts/magento-fix-perms.sh                      # default: namespace=magento2, label=app=magento-php
#   ./scripts/magento-fix-perms.sh -n myns -l "app=magento-php" -c php
#
set -o errexit
set -o nounset
set -o pipefail

NAMESPACE="magento2"
LABEL="app=magento-php"
CONTAINER="php"
TIMEOUT=300   # seconds to wait for pods
SLEEP=3

usage() {
  cat <<EOF
Usage: $0 [-n namespace] [-l podLabel] [-c container] [-t timeout]
  -n namespace   Kubernetes namespace (default: $NAMESPACE)
  -l podLabel    label selector used to find pods (default: $LABEL)
  -c container   container name inside pod (default: $CONTAINER)
  -t timeout     max seconds to wait for pods (default: $TIMEOUT)
EOF
  exit 1
}

while getopts "n:l:c:t:h" opt; do
  case "$opt" in
    n) NAMESPACE="$OPTARG" ;;
    l) LABEL="$OPTARG" ;;
    c) CONTAINER="$OPTARG" ;;
    t) TIMEOUT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

echo "Namespace: $NAMESPACE"
echo "Label selector: $LABEL"
echo "Container: $CONTAINER"
echo

end_time=$(( $(date +%s) + TIMEOUT ))
pods=()

echo "Waiting for pods that match selector [$LABEL] in namespace [$NAMESPACE]..."
while [ $(date +%s) -lt $end_time ]; do
  pods=( $(kubectl get pods -n "$NAMESPACE" -l "$LABEL" -o custom-columns=:metadata.name --no-headers 2>/dev/null || true) )
  if [ ${#pods[@]} -gt 0 ]; then
    echo "Found pods by label: ${pods[*]}"
    break
  fi
  pods=( $(kubectl get pods -n "$NAMESPACE" -o custom-columns=:metadata.name --no-headers 2>/dev/null | grep -E 'magento-php' || true) )
  if [ ${#pods[@]} -gt 0 ]; then
    echo "Found pods by name substring 'magento-php': ${pods[*]}"
    break
  fi
  sleep $SLEEP
done

if [ ${#pods[@]} -eq 0 ]; then
  echo "No pods found for selector '$LABEL' or name 'magento-php' in namespace '$NAMESPACE' (timeout). Exiting."
  kubectl get pods -n "$NAMESPACE" --no-headers || true
  exit 1
fi

REMOTE_CMD=$(cat <<'REMOTE'
set -o errexit
set -o nounset
set -o pipefail

ROOT="/var/www/html"

cd "$ROOT" || { echo "Cannot cd to $ROOT"; exit 2; }

echo "Creating necessary directories (if missing)..."
mkdir -p var/page_cache var/cache var/di var/view_preprocessed pub/static/_cache || true

echo "Attempt chown: numeric UID 1000 (common) then common web users..."
chown -R 1000:1000 var pub generated vendor 2>/dev/null || true
chown -R www-data:www-data var pub generated vendor 2>/dev/null || true
chown -R apache:apache var pub generated vendor 2>/dev/null || true

echo "Setting safe permissions: dirs 775, files 664"
find var pub generated vendor -type d -exec chmod 775 {} + 2>/dev/null || true
find var pub generated vendor -type f -exec chmod 664 {} + 2>/dev/null || true

echo "Ensure page_cache exists and is writable by owner"
mkdir -p var/page_cache || true
chmod 775 var/page_cache 2>/dev/null || true

echo "PERMISSIONS_FIXED"
REMOTE
)

for pod in "${pods[@]}"; do
  echo "-> Fixing permissions in pod: $pod (container: $CONTAINER)"
  if kubectl exec -n "$NAMESPACE" "$pod" -c "$CONTAINER" -- bash -lc "$REMOTE_CMD" 2>/dev/null | tail -n1 | grep -q "PERMISSIONS_FIXED"; then
    echo "  done (bash)"
    continue
  fi
  if kubectl exec -n "$NAMESPACE" "$pod" -c "$CONTAINER" -- sh -c "$REMOTE_CMD" 2>/dev/null | tail -n1 | grep -q "PERMISSIONS_FIXED"; then
    echo "  done (sh)"
    continue
  fi
  echo "  warning: unable to run remote fix in pod $pod. Pod may not have sh/bash or exec permission denied."
done

echo
echo "Permission fix complete. If you still see permission issues, consider adding an initContainer to chown mounts or ensure pod runs as root for init steps."
exit 0

