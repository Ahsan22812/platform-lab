# kube-prometheus-stack

The metrics half of the observability layer: Prometheus Operator,
Prometheus, Alertmanager, node-exporter, kube-state-metrics, and the
ServiceMonitor / PodMonitor / PrometheusRule CRDs.

**Grafana lives separately** at [`../grafana/`](../grafana/) — own
upgrade cadence, and it will host datasources beyond Prometheus (Loki,
Tempo, Thanos) as the lab grows.

Chart: <https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack>
— **vendored** in [`charts/`](charts/) as a versioned `.tgz` with a
`.sha256` and `SOURCE.txt`. Install verifies the checksum and uses the
local tarball; no `helm repo add`. See
[ADR 0004](../../../docs/decisions/0004-vendor-helm-charts.md).

## Install

**Deployed by Argo CD** — this directory is an umbrella chart (the
vendored `.tgz` renders as its subchart; the operator CRDs apply via the
fleet-wide `ServerSideApply=true` sync option, which is what makes the
huge CRDs applyable at all). The `platform-observability` ApplicationSet
([`platform/gitops/`](../../gitops/)) generates the Application; changes
deploy by **git push**, not by hand.

Note the ROOT-level toggles at the top of `values.yaml` — the chart's
five conditional dependencies (crds, kube-state-metrics, node-exporter,
grafana, windows-exporter) are controlled there, because Helm resolves
dependency conditions against root values, and a missing path means
*included*.

To bump the chart: pull the new `.tgz` + regenerate `.sha256` per
[`charts/SOURCE.txt`](charts/SOURCE.txt), update the version in
`Chart.yaml`'s `dependencies`, push.

Break-glass only (Argo CD itself down):
```bash
helm upgrade --install kube-prometheus-stack platform/observability/kube-prometheus-stack -n monitoring
```

## Verify

```bash
kubectl get pods -n monitoring
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Open <http://localhost:9090> → *Status → Targets*. Every listed job
should be `up`. (The kind-incompatible jobs — kube-proxy, scheduler,
controller-manager, etcd — are disabled in `values.yaml`, so they
won't appear; see the comment there for why, and the observe-then-fix
exercise.)

## Uninstall

Remove this component's path from
`platform/gitops/applicationset-observability.yaml` and push — the
generator deletes the Application and prunes its resources. (The operator
CRDs installed from the chart's `crds/` directory are deliberately
retained by Helm/Argo CD conventions; deleting them would cascade-delete
every ServiceMonitor/PrometheusRule in the cluster.)

## Choices baked into this install

| Choice | Value | Why |
|---|---|---|
| Chart version | vendored `86.2.3` (Prometheus v3.12.0) | Explicit, reviewable, offline-installable |
| Grafana | disabled | Standalone chart in `../grafana/` |
| Persistence | emptyDir | Temporary — PVCs at Layer 3+ with MinIO/Thanos |
| Retention | 7d | Only matters once storage is persistent |
| Disabled scrape jobs | kube-proxy/scheduler/controller-manager/etcd | kind binds these to localhost inside the node; cross-node scrape fails |
| Monitor/Rule selectors | namespace-wide | So podinfo (own namespace) gets scraped |
| Resources | requests + memory limit, no cpu limit | Always reserve; cpu limit causes throttling. Right-size from usage later |
