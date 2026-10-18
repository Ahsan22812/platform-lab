# Fluent Bit

The **log shipper** — a DaemonSet (one pod per node) that tails
container logs, enriches them with Kubernetes metadata, and pushes them
to [Loki](../loki/). Grafana then queries Loki.

**Why Fluent Bit (not Grafana Alloy):** it's vendor-neutral (CNCF
graduated) and fans out to *multiple* backends. When EFK lands, an
Elasticsearch output is added to the **same** DaemonSet — one collector
feeds both Loki and Elasticsearch, instead of running two collectors.

Chart: `fluent/fluent-bit` — **vendored** in [`charts/`](charts/)
(`.tgz` + `.sha256` + `SOURCE.txt`, ADR 0004). appVersion 5.0.7.

## Install

**Deployed by Argo CD** — this directory is an umbrella chart (the
vendored `.tgz` renders as its subchart). The `platform-observability`
ApplicationSet ([`platform/gitops/`](../../gitops/)) generates the
Application; changes deploy by **git push**, not by hand. Loki ordering
sorts itself out — the Loki output retries until the Service exists.

To bump the chart: pull the new `.tgz` + regenerate `.sha256` per
[`charts/SOURCE.txt`](charts/SOURCE.txt), update the version in
`Chart.yaml`'s `dependencies`, push.

Break-glass only (Argo CD itself down):
```bash
helm upgrade --install fluent-bit platform/observability/fluent-bit -n monitoring
```

## Verify

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=fluent-bit -o wide   # one per node
```

Then in Grafana → Explore → **Loki** datasource, query logs by label —
e.g. `{namespace="podinfo"}`, `{pod=...}`, `{container=...}`. The label
names are set by `Label_Keys` in `values.yaml` (a `nest`/`lift` +
`modify` filter pair flattens the k8s metadata and renames it to these
short labels).

## Uninstall

Remove this component's path from
`platform/gitops/applicationset-observability.yaml` and push — the
generator deletes the Application and prunes its resources.

## Choices baked into this install

| Choice | Value | Why |
|---|---|---|
| Chart version | vendored `0.57.7` (Fluent Bit 5.0.7) | Explicit, reviewable, offline-installable |
| Workload | DaemonSet, tolerates control-plane taint | Collect logs from every node incl. control-plane |
| Log parsing | `tail` + `multiline.parser cri` | kind runs containerd → CRI log format |
| Enrichment | `kubernetes` filter | Adds namespace/pod/container metadata |
| Output | Loki (`loki:3100`); ES added later | One shipper, multiple backends (EFK reuses this) |
| Stream labels | namespace/pod/container only | Keep Loki cardinality bounded |
| Resources | requests + memory limit, no cpu limit | Reserve always; cpu limit throttles |
