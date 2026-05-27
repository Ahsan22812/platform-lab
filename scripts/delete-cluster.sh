#!/usr/bin/env bash
#
# Delete the platform-lab kind cluster.
# No-op if the cluster doesn't exist.

set -euo pipefail

CLUSTER_NAME="platform-lab"

log()  { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }

if ! command -v kind >/dev/null 2>&1; then
  echo "error: kind not found on PATH" >&2
  exit 1
fi

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  warn "cluster '$CLUSTER_NAME' does not exist — nothing to delete"
  exit 0
fi

log "deleting kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME"
ok "cluster deleted"
