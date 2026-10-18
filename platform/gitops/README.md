# GitOps (Argo CD)

This directory holds the GitOps control plane: **Argo CD** (the engine) and
the **ApplicationSet** that tells it what to manage.

- [`argocd/`](argocd/) — Argo CD itself, installed imperatively
  (`install.sh`, vendored chart). It's the bootstrap: the one thing not
  managed by GitOps, because it can't deploy itself before it exists.
- [`applicationset.yaml`](applicationset.yaml) — the GitOps **root** for
  authored charts. A Git-directory generator that scans `charts/*` and
  creates one Argo CD Application per chart (excluding the `common`
  library chart). Applied once with `kubectl`; from there, adding a chart
  under `charts/` makes it a managed app automatically.
- [`applicationset-observability.yaml`](applicationset-observability.yaml)
  — same pattern for the observability stack
  (`platform/observability/*`), which breaks the root's conventions:
  fixed `monitoring` namespace, umbrella charts wrapping vendored
  tarballs (ADR 0004), and an explicit path list instead of a glob.

## Bootstrap order

```bash
# 1. Install Argo CD (once).
./platform/gitops/argocd/install.sh

# 2. The one secret not in git (Grafana's admin credentials).
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin --from-literal=admin-password=<yours>

# 3. Apply both ApplicationSet roots (once). They generate the Applications.
kubectl apply -f platform/gitops/applicationset.yaml
kubectl apply -f platform/gitops/applicationset-observability.yaml
```

Everything the ApplicationSet manages must be **committed and pushed** —
Argo CD reads the GitHub remote, not your working tree.

## Sync policy: fully automated

Both ApplicationSets run apps with automated reconciliation:

```yaml
      syncPolicy:
        automated:
          selfHeal: true   # revert manual kubectl drift back to git
          prune: true      # delete resources removed from git
        syncOptions:
          - CreateNamespace=true
          - PruneLast=true        # prune only after everything else syncs
          - ServerSideApply=true  # field ownership via managedFields; no
                                  # 256KB last-applied annotation, so huge
                                  # CRDs (Prometheus Operator) apply cleanly
```

> **Lab vs production:** in the lab we enable `selfHeal`/`prune` for the
> learning payoff — watching Argo CD undo a manual `kubectl edit` is the
> point. In production many teams keep both *off* for emergency manual
> intervention and prune deliberately. Noted so the difference is explicit.

## Migrating a Helm-installed app to GitOps

All components are migrated (the per-component `install.sh` scripts are
gone), but the pattern for any future case: remove the imperative Helm
release first, so Argo CD owns the app cleanly with a single source of
truth:

```bash
helm uninstall <release> -n <ns>   # Argo CD recreates + owns it on sync
```

Push the component to the remote **before** applying/annotating the
ApplicationSet — Argo CD reads GitHub, not your working tree; an
unpushed umbrella shows as `Unknown`.

## Sync latency: `Synced` can be one commit behind

Argo CD learns about new commits by **polling** GitHub (~every 3 min).
Between your push and the next poll, an app reports `Synced`/`Healthy`
against the **last revision Argo CD fetched** — truthfully, but one
commit behind. Not a failure; just latency. To force an immediate
re-read of the remote:

```bash
kubectl annotate application <app> -n argocd argocd.argoproj.io/refresh=hard --overwrite
```

The real fix is a GitHub webhook to Argo CD's `/api/webhook`
(push-triggered syncs in seconds) — blocked until the cluster has an
inbound path, tracked under External access in
[`docs/roadmap.md`](../../docs/roadmap.md).
