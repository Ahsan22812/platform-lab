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

## Pushing a config change (hot reload)

Config changes apply **live, without pod restarts**: a `configmap-reload`
sidecar watches the mounted config and calls Fluent Bit's
`/api/v2/reload` when the kubelet syncs the ConfigMap (~1 min after
Argo CD applies it).

The catch: a **rejected** reload (invalid config) is silent — pods stay
Ready on the old config, and Fluent Bit exposes no failed-reload metric,
only the success counter. So every config push ends with verifying that
counter bumped on **every** pod:

```bash
kubectl -n monitoring port-forward svc/prometheus-operated 9090:9090 >/dev/null 2>&1 & PF=$!; sleep 5
curl -s 'localhost:9090/api/v1/query?query=fluentbit_hot_reloaded_times' \
  | jq -r '.data.result[] | "\(.metric.pod)\t\(.value[1])"'
kill $PF
```

Every pod should show the count incremented (counts reset to 0 on pod
restart — a restarted pod read the new config at boot, so 0 is fine
*for that pod*). A pod stuck at the old count rejected the reload: fix
the config and push again — **don't** leave it, or the broken config
loads cold on the next natural restart. The alerts in
[`templates/fluent-bit-alerts.yaml`](templates/fluent-bit-alerts.yaml)
back this up by firing on the consequences (pod down, nothing shipped,
outputs failing).

## Verify

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=fluent-bit -o wide   # one per node, 2/2 (fluent-bit + reloader)
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
| Config rollout | hot reload (sidecar), not checksum-restart | Gapless pushes, buffers survive; trade-off + compensating alerts in `values.yaml` |
| Self-monitoring | ServiceMonitor + PrometheusRule | A log shipper you don't monitor fails silently |
