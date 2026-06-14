# Grafana

Standalone Grafana — the visualisation/alerting UI on top of Prometheus
(and later Loki, Tempo, Thanos).

Separate chart from `kube-prometheus-stack/` because:

- independent upgrade cadence (bump Grafana without churning the metrics stack)
- cleaner story for multiple datasources registered in one place
- better fit for SSO / OAuth when that lands
- clean ownership boundary

Chart: <https://github.com/grafana-community/helm-charts/tree/main/charts/grafana>
(moved from `grafana/helm-charts` in Jan 2026 — old repo deprecated).
**Vendored** in [`charts/`](charts/) as a versioned `.tgz` with `.sha256`
and `SOURCE.txt`; install verifies the checksum and uses the local
tarball, no `helm repo add`. See
[ADR 0004](../../../docs/decisions/0004-vendor-helm-charts.md).

## Install

kube-prometheus-stack must be installed first (provides the Prometheus
datasource this chart points at — `install.sh` checks for it).

```bash
export KUBECONFIG=~/.kube/platform-lab.yaml   # if not already set
./install.sh                                   # admin / admin
GRAFANA_ADMIN_PASSWORD='something-real' ./install.sh   # or override
```

## Verify

```bash
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Open <http://localhost:3000>, log in `admin` / `$GRAFANA_ADMIN_PASSWORD`
(default `admin`). The Prometheus datasource is provisioned from
`values.yaml`; these dashboards are vendored in [`dashboards/`](dashboards/)
and loaded as ConfigMaps that the sidecar imports (see
[`dashboards/SOURCE.txt`](dashboards/SOURCE.txt)):

- *Node Exporter Full* (1860)
- *Kubernetes Cluster (Prometheus)* (7249)
- *Kubernetes / Views / Namespaces* (15758)
- *Kubernetes / Views / Global* (15757)

## Default credentials

`admin` / `admin` unless `GRAFANA_ADMIN_PASSWORD` was set at install.
Temporary — the env-var + `--set-string` path is the wrong pattern and
is scheduled for refactor at **Layer 5** (Secret via Vault + ESO). See
[`TODO.md`](TODO.md).

## Uninstall

```bash
helm uninstall grafana -n monitoring
# Dashboard ConfigMaps are created out-of-band (install.sh), so remove them too:
kubectl delete configmap -n monitoring -l grafana_dashboard=1
```

## Choices baked into this install

| Choice | Value | Why |
|---|---|---|
| Chart version | vendored `12.4.5` (Grafana 13.0.2) | Explicit, reviewable, offline-installable |
| Persistence | disabled | Temporary — dashboards re-provision from values; PVC at Layer 3+ |
| Replicas | 1 | Constraint: HA needs an external shared DB, out of scope for the lab |
| Datasources | Prometheus only | Loki/Tempo/Thanos added here later |
| Dashboards | vendored JSON (`dashboards/`) via ConfigMap + sidecar | No grafana.com fetch at pod start; closes ADR 0004's 3rd external dep |
| Dashboard/datasource sidecars | enabled, all namespaces | Other charts ship dashboards as labelled ConfigMaps |
| Pod security | non-root (uid 472), seccomp, dropped caps | Matches the podinfo chart pattern |
| Resources | requests + memory limit, no cpu limit | Reserve always; cpu limit throttles a UI workload |
| Sign-up | disabled | Admin manages users |
