#!/usr/bin/env bash
#
# Install Loki on the platform-lab kind cluster.
#
# Idempotent: re-running upgrades to the vendored chart version.
# Installs from the LOCAL vendored chart (charts/*.tgz) — no helm repo
# add. See ../../../docs/decisions/0004.
#
# Loki is the log STORE. Logs are shipped to it by Fluent Bit (see
# ../fluent-bit/). Grafana queries it via a datasource (the sidecar
# picks up a ConfigMap shipped here).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

RELEASE="loki"
NAMESPACE="monitoring"
CHART_VERSION="17.4.1"          # vendored; bump per charts/SOURCE.txt
CHART="$SCRIPT_DIR/charts/${RELEASE}-${CHART_VERSION}.tgz"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
EXPECTED_KUBE_CONTEXT="kind-platform-lab"

require_cmd helm kubectl
require_kube_context "$EXPECTED_KUBE_CONTEXT"
[[ -f "$CHART" ]] || die "vendored chart not found at $CHART"
[[ -f "$VALUES_FILE" ]] || die "values file not found at $VALUES_FILE"

# Integrity: vendored tarball must match its recorded checksum.
# (.sha256 holds a bare filename, so verify from inside charts/.)
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

# Ship the Loki datasource for Grafana (its sidecar auto-imports the
# labelled ConfigMap). Out-of-band from the chart — `helm uninstall`
# won't remove it; delete with: kubectl delete -f datasource.yaml.
log "applying Loki datasource for Grafana"
kubectl apply -f "$SCRIPT_DIR/datasource.yaml"

log "current Loki pods in ns/$NAMESPACE:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=loki
