#!/usr/bin/env bash
#
# Install the podinfo chart on the platform-lab kind cluster.
#
# Idempotent: re-running upgrades the release. This is a hand-authored
# chart (not vendored), so there's no checksum step — helm reads it
# straight from this directory.
#
# The ServiceMonitor only renders once kube-prometheus-stack's CRD
# exists (see templates/servicemonitor.yaml). So on a fresh cluster this
# installs podinfo without it; re-run after kps is up to add scraping.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=../../scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

RELEASE="podinfo"
NAMESPACE="podinfo"
EXPECTED_KUBE_CONTEXT="kind-platform-lab"

require_cmd helm kubectl
require_kube_context "$EXPECTED_KUBE_CONTEXT"

# Vendor the shared 'common' library chart into charts/ (gitignored,
# rebuilt from the in-repo source each run — no drift, works offline).
log "updating chart dependencies (shared 'common' library)"
helm dependency update "$SCRIPT_DIR" >/dev/null

log "installing $RELEASE chart into ns/$NAMESPACE"
helm upgrade --install "$RELEASE" "$SCRIPT_DIR" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --wait \
  --timeout 2m

ok "$RELEASE installed"

if kubectl get servicemonitor "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  ok "ServiceMonitor present (Prometheus Operator CRD detected)"
else
  warn "ServiceMonitor NOT created — install kube-prometheus-stack, then re-run this script"
fi

kubectl get pods -n "$NAMESPACE" -o wide
