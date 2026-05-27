#!/usr/bin/env bash
#
# Create the platform-lab kind cluster.
#
# Idempotent: if the cluster already exists, prints status and exits cleanly.
# Ensures the docker CLI is pointed at Colima (not Docker Desktop) before
# creating the cluster, then switches kubectl to the new context and waits
# for all nodes to be Ready.

set -euo pipefail

CLUSTER_NAME="platform-lab"
KIND_CONFIG="$(cd "$(dirname "$0")/.." && pwd)/clusters/kind/kind-config.yaml"
CONTEXT="kind-${CLUSTER_NAME}"
EXPECTED_DOCKER_CONTEXT="colima"

# Pretty output
log()  { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }

# 1. Sanity checks
for cmd in kind kubectl docker; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command '$cmd' not found on PATH" >&2
    exit 1
  fi
done

# 2. Enforce Colima as the docker context (avoid accidentally creating the
#    cluster on Docker Desktop if both are installed).
current_docker_context="$(docker context show 2>/dev/null || echo unknown)"
if [[ "$current_docker_context" != "$EXPECTED_DOCKER_CONTEXT" ]]; then
  warn "docker context is '$current_docker_context' — switching to '$EXPECTED_DOCKER_CONTEXT'"
  docker context use "$EXPECTED_DOCKER_CONTEXT" >/dev/null
fi

if ! docker info >/dev/null 2>&1; then
  echo "error: docker daemon not reachable — is colima running?" >&2
  echo "       try: colima start" >&2
  exit 1
fi

if [[ ! -f "$KIND_CONFIG" ]]; then
  echo "error: kind config not found at $KIND_CONFIG" >&2
  exit 1
fi

log "docker context : $(docker context show)"
log "kubectl context: $(kubectl config current-context 2>/dev/null || echo none)"

# 3. Skip if cluster already exists
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  warn "cluster '$CLUSTER_NAME' already exists — skipping create"
  kubectl config use-context "$CONTEXT" >/dev/null 2>&1 \
    || warn "could not switch to context '$CONTEXT'"
  kubectl get nodes -o wide || true
  exit 0
fi

# 4. Create
log "creating kind cluster '$CLUSTER_NAME' (this can take a minute or two)..."
kind create cluster --config "$KIND_CONFIG"

# 5. Switch context
kubectl config use-context "$CONTEXT" >/dev/null
ok "kubectl context set to '$CONTEXT'"

# 6. Wait for all nodes to be Ready
log "waiting for nodes to become Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=180s

# 7. Summary
ok "cluster '$CLUSTER_NAME' is up:"
kubectl get nodes -o wide
