# podinfo

Small Go HTTP service used as the baseline workload across the lab.
Source: <https://github.com/stefanprodan/podinfo>

Packaged as a **hand-authored Helm chart** — the lab's exercise in chart
*authoring* (the vendored observability charts taught chart *consuming*).
Templates share labels via `templates/_helpers.tpl`, so the Deployment
selector, Service, PDB, and ServiceMonitor can't drift apart.

## What gets deployed

- Deployment: 3 replicas of `ghcr.io/stefanprodan/podinfo` (digest-pinned)
- Service: ClusterIP `podinfo.podinfo.svc.cluster.local:80`
- PodDisruptionBudget: `maxUnavailable: 1`
- ServiceMonitor: scrapes `/metrics` on port 9898 — **only when the
  Prometheus Operator CRD exists** (see below)

Probes hit `/readyz` and `/healthz`.

## Install

```bash
export KUBECONFIG=~/.kube/platform-lab.yaml   # if not already set
./apps/podinfo/install.sh
```

`install.sh` runs `helm upgrade --install` into the `podinfo` namespace.
It's idempotent — re-run any time.

**ServiceMonitor ordering**: the chart renders the ServiceMonitor only
if the Prometheus Operator's CRD is present in the cluster (a Helm
`.Capabilities` check). So on a fresh cluster podinfo installs cleanly
*without* it; once `kube-prometheus-stack` is installed, **re-run
`install.sh`** and the ServiceMonitor appears. The script tells you
which case you're in.

## Verify

```bash
kubectl get all -n podinfo
kubectl rollout status deployment/podinfo -n podinfo
kubectl get servicemonitor -n podinfo      # present once kps is installed
```

In Prometheus (port-forward, /targets), the target
`serviceMonitor/podinfo/podinfo/0` should appear UP (one per replica).

## Configure

Edit `values.yaml` — `replicaCount`, `image.tag`/`digest`, `resources`,
`podDisruptionBudget.*`, `serviceMonitor.*`. Bumping the image means
updating both the tag and its digest (multi-arch index digest); look it
up with `docker buildx imagetools inspect ghcr.io/stefanprodan/podinfo:<tag>`.

## Remove

```bash
helm uninstall podinfo -n podinfo
```

## Why podinfo

The unofficial "hello world" of cloud-native demos — used in Flux,
Argo, Linkerd, and Cilium tutorials. Multi-arch (ARM/AMD), small
(~30 MB image), and exposes the endpoints we need across layers
(probes, metrics, traces). Used here strictly as scaffolding; the real
subject of each layer is the platform component, not the app.
