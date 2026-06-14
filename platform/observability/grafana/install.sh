#!/usr/bin/env bash
#
# Install standalone Grafana on the platform-lab kind cluster.
#
# Idempotent: re-running upgrades to the vendored chart version.
# Installs from the LOCAL vendored chart (charts/*.tgz) — no helm repo
# add. See ../../../docs/decisions/0004.
#
# kube-prometheus-stack must be installed first (provides the Prometheus
# this Grafana points at). Admin password defaults to "admin"; override:
#   GRAFANA_ADMIN_PASSWORD=better-pass ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# shellcheck source=../../../scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

RELEASE="grafana"
NAMESPACE="monitoring"
CHART_VERSION="12.4.5"          # vendored; bump per charts/SOURCE.txt
CHART="$SCRIPT_DIR/charts/${RELEASE}-${CHART_VERSION}.tgz"
VALUES_FILE="$SCRIPT_DIR/values.yaml"
EXPECTED_KUBE_CONTEXT="kind-platform-lab"

GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:-admin}"

require_cmd helm kubectl
require_kube_context "$EXPECTED_KUBE_CONTEXT"
[[ -f "$CHART" ]] || die "vendored chart not found at $CHART"
[[ -f "$VALUES_FILE" ]] || die "values file not found at $VALUES_FILE"

# Fail early if the Prometheus datasource target isn't there yet —
# Grafana would install fine but its datasource would silently 404.
kubectl get svc -n "$NAMESPACE" kube-prometheus-stack-prometheus >/dev/null 2>&1 \
  || die "service 'kube-prometheus-stack-prometheus' not found in ns/$NAMESPACE — install kube-prometheus-stack first"

# Integrity: vendored tarball must match its recorded checksum.
# (.sha256 holds a bare filename, so verify from inside charts/.)
log "verifying chart checksum"
( cd "$SCRIPT_DIR/charts" && shasum -c "${RELEASE}-${CHART_VERSION}.tgz.sha256" )

log "installing $RELEASE (chart $CHART_VERSION) into ns/$NAMESPACE"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values "$VALUES_FILE" \
  --set-string adminUser=admin \
  --set-string adminPassword="$GRAFANA_ADMIN_PASSWORD" \
  --wait \
  --timeout 5m

ok "$RELEASE installed"

# Load vendored dashboards (dashboards/*.json) as ConfigMaps labelled
# grafana_dashboard=1; the sidecar auto-imports them. Created out-of-band
# from the chart (kubectl, not helm) — `helm uninstall` won't remove them.
#
# Server-side apply (not the usual create|apply): client-side apply stores
# the whole object in a last-applied annotation, capped at 256KB — large
# dashboards (node-exporter-full is ~484KB) exceed it. Server-side apply
# tracks ownership in managedFields instead, so there's no such limit.
log "loading vendored dashboards as ConfigMaps"
for f in "$SCRIPT_DIR"/dashboards/*.json; do
  cm="grafana-dashboard-$(basename "$f" .json)"
  kubectl create configmap "$cm" -n "$NAMESPACE" --from-file="$f" \
    --dry-run=client -o yaml \
    | kubectl apply --server-side --force-conflicts -f - >/dev/null
  kubectl label configmap "$cm" -n "$NAMESPACE" grafana_dashboard=1 --overwrite >/dev/null
  ok "  $cm"
done

log "to open Grafana:"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo "  then http://localhost:3000  (admin / \$GRAFANA_ADMIN_PASSWORD)"
