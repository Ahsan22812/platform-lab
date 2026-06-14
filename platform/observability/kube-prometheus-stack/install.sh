#!/usr/bin/env bash
#
# Install kube-prometheus-stack on the platform-lab kind cluster.
#
# Idempotent: re-running upgrades to the vendored chart version.
# Installs from the LOCAL vendored chart (charts/*.tgz) — no helm repo
# add, no network fetch for the chart. See ../../../docs/decisions/0004.
# Grafana is intentionally NOT installed here — see ../grafana/.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

RELEASE="kube-prometheus-stack"
NAMESPACE="monitoring"
CHART_VERSION="86.2.3"          # vendored; bump per charts/SOURCE.txt
CHART="$SCRIPT_DIR/charts/${RELEASE}-${CHART_VERSION}.tgz"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
EXPECTED_KUBE_CONTEXT="kind-platform-lab"

require_cmd helm kubectl
require_kube_context "$EXPECTED_KUBE_CONTEXT"
[[ -f "$CHART" ]] || die "vendored chart not found at $CHART"
[[ -f "$VALUES_FILE" ]] || die "values file not found at $VALUES_FILE"

# Integrity: the vendored tarball must match its recorded checksum
# before we install it. (.sha256 holds a bare filename, so verify from
# inside charts/.)
log "verifying chart checksum"
( cd "$SCRIPT_DIR/charts" && shasum -c "${RELEASE}-${CHART_VERSION}.tgz.sha256" )

log "installing $RELEASE (chart $CHART_VERSION) into ns/$NAMESPACE"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$VALUES_FILE" \
  --wait \
  --timeout 10m

ok "$RELEASE installed"

log "current pods in ns/$NAMESPACE:"
kubectl get pods -n "$NAMESPACE"
