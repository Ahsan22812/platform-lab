#!/usr/bin/env bash
#
# Re-fetch the vendored Grafana dashboards from grafana.com and bind them
# to our Prometheus datasource (uid: prometheus, set in ../values.yaml).
#
# GNet dashboards ship with datasource placeholders meant to be filled in
# at manual import time (${DS_PROMETHEUS}) or via a template variable
# (${datasource}). Provisioned dashboards don't get that interactive
# step, so we substitute both to our datasource uid at vendor time.
#
# Run this only when bumping a dashboard revision (edit the list below),
# then review `git diff` and commit the regenerated JSON. See SOURCE.txt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DS_UID="prometheus"

# name : grafana.com dashboard id : revision
DASHBOARDS=(
  "node-exporter-full:1860:41"
  "k8s-cluster-overview:7249:1"
  "k8s-namespace-pods:15758:36"
  "k8s-views-global:15757:43"
)

for spec in "${DASHBOARDS[@]}"; do
  name="${spec%%:*}"; rest="${spec#*:}"; id="${rest%%:*}"; rev="${rest##*:}"
  echo "fetching $name (gnetId $id, revision $rev)"
  curl -fsSL "https://grafana.com/api/dashboards/${id}/revisions/${rev}/download" \
    | sed -e "s/\${DS_PROMETHEUS}/${DS_UID}/g" \
          -e "s/\${datasource}/${DS_UID}/g" \
    > "$SCRIPT_DIR/${name}.json"
done

echo "done — review 'git diff' and commit the regenerated JSON"
