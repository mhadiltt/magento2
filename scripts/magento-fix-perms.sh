#!/bin/sh

set -eu

NAMESPACE="magento2"
LABEL="app=magento-php"
CONTAINER="php"
POD_NAME=""
TIMEOUT=300
SLEEP=3

usage() {
  cat <<EOF
Usage: $0 [-n namespace] [-l podLabel] [-c container] [-p podName] [-t timeout]
  -n namespace   Kubernetes namespace (default: $NAMESPACE)
  -l podLabel    label selector used to find pods (default: $LABEL)
  -c container   container name inside pod (default: $CONTAINER)
  -p podName     specific pod name (NO kubectl get/list calls)
  -t timeout     max seconds to wait for pods discovery (default: $TIMEOUT)
EOF
  exit 1
}

while getopts "n:l:c:p:t:h" opt; do
  case "$opt" in
    n) NAMESPACE="$OPTARG" ;;
    l) LABEL="$OPTARG" ;;
    c) CONTAINER="$OPTARG" ;;
    p) POD_NAME="$OPTARG" ;;
    t) TIMEOUT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

echo "Namespace: $NAMESPACE"
echo "Label selector: $LABEL"
echo "Container: $CONTAINER"
if [ -n "$POD_NAME" ]; then
  echo "Pod name override: $POD_NAME"
fi
echo

pods=""

if [ -n "$POD_NAME" ]; then
  pods="$POD_NAME"
else
  end_time=$(($(date +%s) + TIMEOUT))

  echo "Waiting for pods that match selector [$LABEL] in namespace [$NAMESPACE]..."
  while [ "$(date +%s)" -lt "$end_time" ]; do
    pods=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL" -o custom-columns=:metadata.name --no-headers 2>/dev/null | xargs || true)

    if echo "$pods" | grep -qi "forbidden"; then
      echo "RBAC forbids listing pods in namespace [$NAMESPACE]. Skipping permission fix."
      exit 0
    fi

    if [ -n "$pods" ]; then
      echo "Found pods by label: $pods"
      break
    fi

    pods=$(kubectl get pods -n "$NAMESPACE" -o custom-columns=:metadata.name --no-headers 2>/dev/null | grep -E 'magento-php' | xargs || true)
    if [ -n "$pods" ]; then
      echo "Found pods by name substring 'magento-php': $pods"
      break
    fi

    sleep "$SLEEP"
  done
fi

if [ -z "$pods" ]; then
  echo "No pods available for selector '$LABEL' or provided name in namespace '$NAMESPACE'. Skipping permission fix."
  exit 0
fi

REMOTE_CMD=$(cat <<'REMOTE'
set -eu

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

for pod in $pods; do
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
echo "Permission fix complete (or skipped if RBAC/pods not available)."
exit 0
