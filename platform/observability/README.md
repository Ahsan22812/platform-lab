# Observability

Cluster-wide telemetry: metrics, logs, traces.

## Components

| Path | What | Status |
|---|---|---|
| [`kube-prometheus-stack/`](kube-prometheus-stack/) | Metrics — Prometheus, Alertmanager, node-exporter, kube-state-metrics, operator | installed |
| [`grafana/`](grafana/) | Visualisation & alerting UI (standalone), with vendored dashboards | installed |
| `loki/` | Logs | Layer 2 (planned) |

## Install order

1. `kube-prometheus-stack` (provides the Prometheus datasource Grafana points at)
2. `grafana` (depends on Prometheus existing)
3. `loki` (datasource added to Grafana after install)

## Why Grafana is split out from `kube-prometheus-stack`

The Helm chart `kube-prometheus-stack` can bundle Grafana, but we run
it separately. Reasons:

- Independent upgrade cadence — bump Grafana without churning the
  metrics stack
- Cleaner story for multiple datasources (Loki, Tempo, Thanos all
  registered in one place)
- Better fit for SSO / OAuth integration when that comes
- Matches the pattern most mature platform teams use

## Production-shaped, not (yet) production-grade

The architecture here mirrors how mature platform teams structure
observability — Prometheus Operator with ServiceMonitor / PodMonitor
CRDs, Grafana split out, room for Loki/Tempo/Thanos to slot in
cleanly. But several capabilities deliberately stop short of what
real production would require.

Tracked deferrals:

- Grafana admin credential via External Secrets Operator + Vault
  (lab uses env-var + `--set-string` for now) — Layer 5
- Persistent storage for Prometheus, Alertmanager, and Grafana
  (lab uses `emptyDir`) — Layer 3+ when Thanos lands
- Prometheus / Alertmanager HA with multiple replicas — out of scope
  for a 3-node lab
- TLS + Ingress + SSO for Grafana — when Ingress lands
- Long-term metrics storage (Thanos / Mimir / VictoriaMetrics) —
  Layer 3+ via Thanos sidecar pattern
- Alert rules as code (custom PrometheusRule resources) — added
  per-component as we install things worth alerting on

Dashboards are already vendored as version-controlled JSON
(`grafana/dashboards/`) and loaded via ConfigMap + sidecar — no
grafana.com fetch at pod start (closed ADR 0004's third external dep).

## Deferred

- **Tempo** (distributed tracing) — Layer 6, once we have a real
  traced application.
- **Thanos** (long-term metrics storage + global view) — Layer 3+,
  once MinIO is installed for Velero. Reusing the same object store.
