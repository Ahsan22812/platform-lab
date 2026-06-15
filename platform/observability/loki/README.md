# Loki

The **log store** half of observability — Grafana Loki, queried from
Grafana alongside Prometheus metrics.

Loki only *stores* logs; it doesn't collect them. **Fluent Bit**
([`../fluent-bit/`](../fluent-bit/)) tails pod logs and pushes them
here. Grafana queries Loki via a datasource (shipped as a ConfigMap the
Grafana sidecar auto-imports).

Chart: `grafana-community/loki` (Grafana-endorsed maintainer) —
**vendored** in [`charts/`](charts/) (`.tgz` + `.sha256` + `SOURCE.txt`,
ADR 0004). appVersion 3.7.2.

## Install

```bash
export KUBECONFIG=~/.kube/platform-lab.yaml   # if not already set
./platform/observability/loki/install.sh
```

Install order: Loki → Fluent Bit (needs Loki's endpoint). Grafana can be
installed before or after — its datasource sidecar picks Loki up whenever
the datasource ConfigMap appears.

## Verify

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
```

Once Fluent Bit is shipping and the datasource is loaded, query logs in
Grafana (Explore → Loki) with e.g. `{namespace="podinfo"}`.

## Uninstall

```bash
helm uninstall loki -n monitoring
```

## Choices baked into this install

| Choice | Value | Why |
|---|---|---|
| Chart version | vendored `17.4.1` (Loki 3.7.2) | Explicit, reviewable, offline-installable |
| Deployment mode | SingleBinary (monolithic) | Simplest topology; one pod runs all components |
| Storage | filesystem + emptyDir | Temporary — object storage (MinIO/S3) + PVCs at Layer 3+ |
| Retention | 7d | Moot until storage is persistent |
| Auth | disabled (single-tenant) | No multi-tenancy needed in the lab |
| Gateway | disabled | Clients hit the `loki` Service :3100 directly |
| Caches / canary / MinIO subchart | disabled | Trim pods a tiny lab doesn't need |
| Resources | requests + memory limit, no cpu limit | Reserve always; cpu limit throttles |
