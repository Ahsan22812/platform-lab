# Troubleshooting

Common issues encountered while running the lab, with fixes.

---

## Control-plane scrape targets down on kind (kube-proxy/scheduler/controller-manager/etcd)

### Symptom

After installing kube-prometheus-stack, Prometheus *Status → Targets*
shows six targets down, all with `connect: connection refused`:

```
kube-controller-manager: Get "https://172.18.0.3:10257/metrics": ... connection refused
kube-scheduler:          Get "https://172.18.0.3:10259/metrics": ... connection refused
kube-etcd:               Get "http://172.18.0.3:2381/metrics":   ... connection refused
kube-proxy:              Get "http://172.18.0.{2,3,4}:10249/metrics": ... connection refused
```

(kube-proxy appears three times — it's a DaemonSet, one pod per node;
the control-plane trio appears once, on the single control-plane node.)
Their default alert rules also fire.

### Cause

On kind, these components bind their metrics endpoints to `127.0.0.1`
*inside* each node container — kube-controller-manager and kube-scheduler
default to `--bind-address=127.0.0.1`, kube-proxy's `metricsBindAddress`
defaults to localhost, and etcd's `:2381` metrics port isn't exposed.
Prometheus runs on a different node and scrapes the node's routable IP
(172.18.0.x), where nothing is listening — hence "connection refused".
Not broken; the endpoints simply aren't reachable across nodes.

### Fix

Disable those four scrape jobs in
`platform/observability/kube-prometheus-stack/values.yaml`:

```yaml
kubeControllerManager:
  enabled: false
kubeScheduler:
  enabled: false
kubeEtcd:
  enabled: false
kubeProxy:
  enabled: false
```

Re-run `./platform/observability/kube-prometheus-stack/install.sh`.
This stops generating the ServiceMonitors (and removes the default
alert rules that reference them). Confirmed: down targets dropped from
6 to 0, leaving 21 up. Prometheus may take ~15–30s to reload and drop
the stale targets.

### On managed clusters (EKS / AKS) — same setting, different reasons

Don't over-generalize "always disable on kind" into "always disable":
the config is environment-specific.

- **scheduler / controller-manager / etcd** — also disabled on EKS/AKS,
  but because the control plane is provider-managed and those endpoints
  aren't exposed to you at all (get that observability from CloudWatch
  Container Insights / Azure Monitor instead), not because of localhost
  binding.
- **kube-proxy** — runs as a DaemonSet on *your* worker nodes, so it's
  potentially scrapable. Keep it enabled if its `metricsBindAddress` is
  `0.0.0.0:10249`; if it defaults to `127.0.0.1`, either patch the
  kube-proxy ConfigMap to bind `0.0.0.0` or disable the job. Varies by
  provider/version — check, don't assume.
- **apiserver** — always stays up (reachable via the in-cluster
  `kubernetes` service); never disabled.
- **self-managed kubeadm** — keep all of them, but reconfigure their
  bind addresses to `0.0.0.0` rather than disabling.

## Template

### Symptom

What you saw (error message, behavior).

### Cause

What was actually wrong.

### Fix

What resolved it. Include exact commands.
