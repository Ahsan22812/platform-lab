# Argo CD

The **GitOps engine** — Argo CD watches this repo and continuously
reconciles the cluster to match what's declared in git. Drift gets
corrected, deploys happen by `git push`, and you get a UI + history.

Argo CD is the cluster's **bootstrap**: it's the one component installed
imperatively (`install.sh`), and from there it manages everything else
declaratively. Later it can even manage *itself* (an Application pointing
back at this directory).

Chart: `argo/argo-cd` (argoproj/argo-helm) — **vendored** in
[`charts/`](charts/) (`.tgz` + `.sha256` + `SOURCE.txt`, ADR 0004).
appVersion v3.4.3.

## Install

```bash
export KUBECONFIG=~/.kube/platform-lab.yaml   # if not already set
./platform/gitops/argocd/install.sh
```

## Verify

```bash
kubectl get pods -n argocd
```

All pods (server, application-controller, repo-server, applicationset
controller, redis) should reach `Running`.

## Access the UI

```bash
# initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo

# port-forward (server runs insecure HTTP — see values.yaml)
kubectl -n argocd port-forward svc/argocd-server 8080:80
```

Open <http://localhost:8080>, log in as `admin`. (Port-forward is the
interim access path; a real URL + SSO arrive with the external-access
phase via Cloudflare Access.)

## Uninstall

```bash
helm uninstall argocd -n argocd
```

## Choices baked into this install

| Choice | Value | Why |
|---|---|---|
| Chart version | vendored `9.5.21` (Argo CD v3.4.3) | Explicit, reviewable, offline-installable |
| Install method | imperative `install.sh` | Argo CD is the bootstrap — it can't GitOps-deploy itself before it exists |
| Namespace | `argocd` | Conventional, isolated from workloads |
| Dex / Notifications | disabled | No external IdP or alert integrations yet (SSO comes at the edge later) |
| ApplicationSet controller | enabled | We use the Git-directory generator to discover apps |
| `server.insecure` | `true` | TLS terminated upstream later (Cloudflare + Istio); avoids self-signed warnings on port-forward |
| Resources | requests + memory limit, no cpu limit | Reserve always; cpu limit throttles |
| Replicas | 1 each | No HA on a 3-node lab |
