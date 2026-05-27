#!/usr/bin/env bash
#
# Create the platform-lab kind cluster.
#
# Idempotent: if the cluster already exists, prints status and exits cleanly.
# Ensures the docker CLI is pointed at Colima (not Docker Desktop) before
# creating the cluster, then switches kubectl to the new context and waits
# for all nodes to be Ready.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

CLUSTER_NAME="platform-lab"
KIND_CONFIG="$REPO_ROOT/clusters/kind/kind-config.yaml"
CONTEXT="kind-${CLUSTER_NAME}"

require_cmd kind kubectl docker
require_docker_context colima
require_docker_daemon
[[ -f "$KIND_CONFIG" ]] || die "kind config not found at $KIND_CONFIG"

log "docker context : $(docker context show)"
log "kubectl context: $(kubectl config current-context 2>/dev/null || echo none)"

# Skip if cluster already exists
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  warn "cluster '$CLUSTER_NAME' already exists — skipping create"
  kubectl config use-context "$CONTEXT" >/dev/null 2>&1 \
    || warn "could not switch to context '$CONTEXT'"
  kubectl get nodes -o wide || true
  exit 0
fi

log "creating kind cluster '$CLUSTER_NAME' (this can take a minute or two)..."
kind create cluster --config "$KIND_CONFIG"

kubectl config use-context "$CONTEXT" >/dev/null
ok "kubectl context set to '$CONTEXT'"

log "waiting for nodes to become Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s

ok "cluster '$CLUSTER_NAME' is up:"
kubectl get nodes -o wide
