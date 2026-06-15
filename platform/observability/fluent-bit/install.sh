#!/usr/bin/env bash
#
# Install Fluent Bit on the platform-lab kind cluster.
#
# Idempotent: re-running upgrades to the vendored chart version.
# Installs from the LOCAL vendored chart (charts/*.tgz) — no helm repo
# add. See ../../../docs/decisions/0004.
#
# Fluent Bit is the log SHIPPER — a DaemonSet that tails pod logs and
# pushes to Loki (../loki/ must be installed first). Vendor-neutral, so
# it can later fan out to Elasticsearch (EFK) from the same DaemonSet.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

RELEASE="fluent-bit"
NAMESPACE="monitoring"
CHART_VERSION="0.57.7"          # vendored; bump per charts/SOURCE.txt
CHART="$SCRIPT_DIR/charts/${RELEASE}-${CHART_VERSION}.tgz"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
EXPECTED_KUBE_CONTEXT="kind-platform-lab"

require_cmd helm kubectl
require_kube_context "$EXPECTED_KUBE_CONTEXT"
[[ -f "$CHART" ]] || die "vendored chart not found at $CHART"
[[ -f "$VALUES_FILE" ]] || die "values file not found at $VALUES_FILE"

# Fail early if Loki isn't there — Fluent Bit would run but its Loki
# output would have nowhere to push.
kubectl get svc -n "$NAMESPACE" loki >/dev/null 2>&1 \
  || die "service 'loki' not found in ns/$NAMESPACE — install Loki first (../loki/)"

# Integrity: vendored tarball must match its recorded checksum.
log "verifying chart checksum"
( cd "$SCRIPT_DIR/charts" && shasum -c "${RELEASE}-${CHART_VERSION}.tgz.sha256" )

log "installing $RELEASE (chart $CHART_VERSION) into ns/$NAMESPACE"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$VALUES_FILE" \
  --wait \
  --timeout 5m

ok "$RELEASE installed"

log "Fluent Bit pods (one per node):"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=fluent-bit -o wide
