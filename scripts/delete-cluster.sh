#!/usr/bin/env bash
#
# Delete the platform-lab kind cluster.
# No-op if the cluster doesn't exist.
#
# Asks for confirmation on a TTY (the cluster is rebuildable, but a
# rebuild costs real time — the prompt guards against fat-fingered
# runs). Non-interactive callers must opt in explicitly with FORCE=1;
# they get a hard refusal instead of a prompt nobody can answer.
#
# Operates on the lab's dedicated kubeconfig (see create-cluster.sh) —
# kind removes the cluster's entries from that file on delete. The
# default ~/.kube/config is never touched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

CLUSTER_NAME="platform-lab"
LAB_KUBECONFIG="${PLATFORM_LAB_KUBECONFIG:-$HOME/.kube/platform-lab.yaml}"

require_cmd kind

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  warn "cluster '$CLUSTER_NAME' does not exist — nothing to delete"
  exit 0
fi

if [[ -t 0 ]]; then
  reply=""
  read -r -p "Delete cluster '$CLUSTER_NAME' and all its workloads? [y/N] " reply || true
  [[ "$reply" == [yY] ]] || die "aborted — nothing deleted"
elif [[ "${FORCE:-}" != "1" ]]; then
  die "refusing to delete non-interactively — re-run with FORCE=1 to override"
fi

log "deleting kind cluster '$CLUSTER_NAME'..."
kind delete cluster --name "$CLUSTER_NAME" --kubeconfig "$LAB_KUBECONFIG"
ok "cluster deleted"
