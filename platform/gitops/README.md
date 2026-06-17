# GitOps (Argo CD)

This directory holds the GitOps control plane: **Argo CD** (the engine) and
the **ApplicationSet** that tells it what to manage.

- [`argocd/`](argocd/) — Argo CD itself, installed imperatively
  (`install.sh`, vendored chart). It's the bootstrap: the one thing not
  managed by GitOps, because it can't deploy itself before it exists.
- [`applicationset.yaml`](applicationset.yaml) — the GitOps **root**. A
  Git-directory generator that scans `charts/*` and creates one Argo CD
  Application per chart (excluding the `common` library chart). Applied
  once with `kubectl`; from there, adding a chart under `charts/` makes it
  a managed app automatically.

## Bootstrap order

```bash
# 1. Install Argo CD (once).
./platform/gitops/argocd/install.sh

# 2. Apply the ApplicationSet root (once). It generates the Applications.
kubectl apply -f platform/gitops/applicationset.yaml
```

Everything the ApplicationSet manages must be **committed and pushed** —
Argo CD reads the GitHub remote, not your working tree.

## Sync policy: manual now, automated later

The ApplicationSet starts apps in **manual sync** — you click *Sync* in the
UI and watch the reconcile. This is the best way to *see* GitOps work.

Once proven, graduate an app to automated reconciliation by adding to the
template's `syncPolicy`:

```yaml
      syncPolicy:
        automated:
          selfHeal: true   # revert manual kubectl drift back to git
          prune: true      # delete resources removed from git
        syncOptions:
          - CreateNamespace=true
          - PruneLast=true  # prune only after everything else syncs
```

> **Lab vs production:** in the lab we enable `selfHeal`/`prune` for the
> learning payoff — watching Argo CD undo a manual `kubectl edit` is the
> point. In production many teams keep both *off* for emergency manual
> intervention and prune deliberately. Noted so the difference is explicit.

## Migrating an `install.sh`-deployed app to GitOps

If a chart was already installed imperatively (e.g. podinfo via its
`install.sh`), remove the Helm release first so Argo CD owns it cleanly with
a single source of truth:

```bash
helm uninstall podinfo -n podinfo   # Argo CD recreates + owns it on sync
```
