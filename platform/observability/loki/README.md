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

**Deployed by Argo CD** — this directory is an umbrella chart (the
vendored `.tgz` renders as its subchart; the Grafana datasource ConfigMap
ships from [`templates/`](templates/)). The `platform-observability`
ApplicationSet ([`platform/gitops/`](../../gitops/)) generates the
Application; changes deploy by **git push**, not by hand.

To bump the chart: pull the new `.tgz` + regenerate `.sha256` per
[`charts/SOURCE.txt`](charts/SOURCE.txt), update the version in
`Chart.yaml`'s `dependencies`, push.

Break-glass only (Argo CD itself down):
```bash
helm upgrade --install loki platform/observability/loki -n monitoring
```

Install order sorts itself out — Fluent Bit retries until Loki's Service
exists; Grafana's sidecar picks the datasource up whenever the ConfigMap
appears.

## Verify

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
```

Once Fluent Bit is shipping and the datasource is loaded, query logs in
Grafana (Explore → Loki) with e.g. `{namespace="podinfo"}`.

## Uninstall

Remove this component's path from
`platform/gitops/applicationset-observability.yaml` and push — the
generator deletes the Application and prunes its resources.

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
