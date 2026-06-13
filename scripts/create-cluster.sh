#!/usr/bin/env bash
#
# Create the platform-lab kind cluster.
#
# Idempotent: if the cluster already exists, prints status and exits cleanly.
# Ensures the docker CLI is pointed at Colima (not Docker Desktop) before
# creating the cluster, then waits for all nodes to be Ready.
#
# The cluster's credentials live in a DEDICATED kubeconfig file
# ($LAB_KUBECONFIG), never in ~/.kube/config. On a machine whose default
# kubeconfig points at other (e.g. work) clusters, this makes lab/work
# cross-contamination structurally impossible: lab shells export
# KUBECONFIG and see only the lab; everything else never learns the lab
# exists. This script never touches the default kubeconfig.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

CLUSTER_NAME="platform-lab"
KIND_CONFIG="$REPO_ROOT/clusters/kind/kind-config.yaml"
CONTEXT="kind-${CLUSTER_NAME}"
LAB_KUBECONFIG="${PLATFORM_LAB_KUBECONFIG:-$HOME/.kube/platform-lab.yaml}"

# Everything in this script (kind + kubectl) operates on the lab
# kubeconfig only.
export KUBECONFIG="$LAB_KUBECONFIG"
# Ensure the kubeconfig's parent dir exists (fresh machine may not have ~/.kube).
mkdir -p "$(dirname "$LAB_KUBECONFIG")"

require_cmd kind kubectl docker
require_docker_context colima
require_docker_daemon
[[ -f "$KIND_CONFIG" ]] || die "kind config not found at $KIND_CONFIG"

log "docker context : $(docker context show)"
log "lab kubeconfig : $LAB_KUBECONFIG"

# Skip if cluster already exists
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  warn "cluster '$CLUSTER_NAME' already exists — skipping create"
  # Regenerate the lab kubeconfig in case it's missing or stale (e.g. a
  # cluster created the old way, before the dedicated-kubeconfig change).
  kind export kubeconfig --name "$CLUSTER_NAME" --kubeconfig "$LAB_KUBECONFIG" >/dev/null 2>&1 \
    || warn "could not export kubeconfig for existing cluster"
  kubectl get nodes -o wide || true
  exit 0
fi

log "creating kind cluster '$CLUSTER_NAME' (this can take a minute or two)..."
kind create cluster --config "$KIND_CONFIG" --kubeconfig "$LAB_KUBECONFIG"

ok "cluster credentials written to $LAB_KUBECONFIG (context '$CONTEXT')"

# Optional local post-create hook for environment-specific setup.
# Lives at scripts/lib/post-create.local.sh, is .gitignore'd, and is
# sourced if present so it has access to common.sh helpers and the
# script's vars.
LOCAL_HOOK="$SCRIPT_DIR/lib/post-create.local.sh"
if [[ -f "$LOCAL_HOOK" ]]; then
  log "running local post-create hook"
  # shellcheck source=/dev/null
  source "$LOCAL_HOOK"
fi

log "waiting for nodes to become Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s

ok "cluster '$CLUSTER_NAME' is up:"
kubectl get nodes -o wide

log "to use the lab from this or any shell:"
echo "  export KUBECONFIG=$LAB_KUBECONFIG"
