#!/usr/bin/env bash
#
# Delete the platform-lab kind cluster.
# No-op if the cluster doesn't exist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

CLUSTER_NAME="platform-lab"

require_cmd kind

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  warn "cluster '$CLUSTER_NAME' does not exist — nothing to delete"
  exit 0
fi

log "deleting kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME"
ok "cluster deleted"
