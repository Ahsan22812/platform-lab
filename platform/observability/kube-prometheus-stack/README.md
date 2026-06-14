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

```bash
export KUBECONFIG=~/.kube/platform-lab.yaml   # if not already set
./install.sh
```

The script verifies the chart checksum, enforces the
`kind-platform-lab` context, and installs into the `monitoring`
namespace from `values.yaml`.

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

```bash
helm uninstall kube-prometheus-stack -n monitoring
```

(Leaves the `monitoring` namespace; Grafana also lives there.)

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
