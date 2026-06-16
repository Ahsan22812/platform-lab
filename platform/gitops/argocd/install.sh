#!/usr/bin/env bash
#
# Install Argo CD on the platform-lab kind cluster.
#
# Idempotent: re-running upgrades to the vendored chart version.
# Installs from the LOCAL vendored chart (charts/*.tgz) — no helm repo
# add. See ../../../docs/decisions/0004.
#
# Argo CD is the GitOps engine and the cluster's BOOTSTRAP: it is installed
# imperatively here, then declaratively manages everything else from git.
# (It can later manage itself via an Application pointing back at this dir.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

RELEASE="argocd"                # helm release name
CHART_NAME="argo-cd"            # upstream chart name (≠ release name)
NAMESPACE="argocd"
CHART_VERSION="9.5.21"          # vendored; bump per charts/SOURCE.txt
CHART="$SCRIPT_DIR/charts/${CHART_NAME}-${CHART_VERSION}.tgz"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
EXPECTED_KUBE_CONTEXT="kind-platform-lab"

require_cmd helm kubectl
require_kube_context "$EXPECTED_KUBE_CONTEXT"
[[ -f "$CHART" ]] || die "vendored chart not found at $CHART"
[[ -f "$VALUES_FILE" ]] || die "values file not found at $VALUES_FILE"

# Integrity: vendored tarball must match its recorded checksum.
# (.sha256 holds a bare filename, so verify from inside charts/.)
log "verifying chart checksum"
( cd "$SCRIPT_DIR/charts" && shasum -c "${CHART_NAME}-${CHART_VERSION}.tgz.sha256" )

log "installing $RELEASE (chart $CHART_VERSION) into ns/$NAMESPACE"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$VALUES_FILE" \
  --wait \
  --timeout 10m

ok "$RELEASE installed"

log "current Argo CD pods in ns/$NAMESPACE:"
kubectl get pods -n "$NAMESPACE"

cat <<'EOF'

Next:
  • Initial admin password:
      kubectl -n argocd get secret argocd-initial-admin-secret \
        -o jsonpath='{.data.password}' | base64 -d; echo
  • Reach the UI (port-forward; server runs insecure HTTP):
      kubectl -n argocd port-forward svc/argocd-server 8080:80
    then open http://localhost:8080 and log in as 'admin'.
EOF
