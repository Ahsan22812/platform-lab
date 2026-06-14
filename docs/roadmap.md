# Roadmap

The lab is built in layers. Each layer adds a concrete capability and gets
documented as it lands. **This file is the single source of truth for the
plan** — folder READMEs may say "planned", but the schedule lives here.

Half-layers (2.5, 3.5) were inserted later; existing layer numbers stay
stable because other docs reference them.

## Layer 1: Foundation

- [x] Repo scaffolded
- [x] Per-directory git identity configured
- [x] First 3 ADRs (Colima, kind, monorepo)
- [x] Toolchain installed (Colima, kind, kubectl, helm, k9s)
- [x] kind cluster config + scripts + Makefile
- [x] Cluster verified (3 nodes Ready, node-failure recovery observed)
- [x] podinfo deployed as baseline workload
- [x] Node-failure runbook (`docs/runbooks/node-failure.md`)

## Layer 2: Observability

- [ ] metrics-server — the `metrics.k8s.io` API (real-time CPU/mem;
      powers `kubectl top`, HPA, and the VPA recommender). Distinct from
      Prometheus, which is historical time-series. On kind needs
      `--kubelet-insecure-tls` (kind's kubelet serving cert isn't signed
      by the cluster CA). Apache-2.0; vendor via the Path C pattern.
- [x] kube-prometheus-stack (Prometheus, Alertmanager; Grafana split out)
- [x] Standalone Grafana (own chart, own upgrade cadence; vendored dashboards)
- [ ] Loki (logs)
- [ ] Right-size resource requests from observed usage. Manual loop
      first (compare requests vs actual in Prometheus after a day of
      runtime — teaches the mechanics). Then the standard production
      tooling: **VPA in recommendation mode** (`updateMode: "Off"` —
      computes recommended requests from real usage, never touches
      pods) + **Goldilocks** dashboard (current vs recommended).
      Caveats: never pair VPA `Auto` with HPA on the same resource;
      `Auto` evicts pods to apply — recommendation-mode + apply-by-hand
      is the conservative default; needs metrics-server (above) or a
      Prometheus history provider. VPA + Goldilocks both Apache-2.0/free,
      confirmed for inclusion.

Tempo (traces) deferred to Layer 6 — tracing needs a real traced
application, which arrives with the stateful workloads.

## Layer 2.5: Ingress & TLS

The kind cluster already maps host ports 80/443 to the control plane
for exactly this.

- [ ] ingress-nginx
- [ ] cert-manager (local CA, TLS for lab hostnames)
- [ ] Grafana behind ingress with TLS (replaces port-forward)
- [ ] Grafana SSO via OIDC — needs an identity provider; slot may shift
      to Layer 5 (Vault) or later, tracked here so it isn't lost

## Layer 3: Backup, DR & Storage

- [ ] Storage decision: local-path (kind default) vs explicit
      provisioner; revisit Longhorn/Rook only if a need appears
- [ ] MinIO as S3 target
- [ ] Velero install
- [ ] Velero restore scenario documented
- [ ] etcd snapshot/restore drill
- [ ] Persistence for observability: PVCs for Prometheus, Alertmanager,
      Grafana, Loki (replaces emptyDir — tracked deferral from Layer 2)
- [ ] Thanos on MinIO (long-term metrics; reuses the Velero object store)

## Layer 3.5: GitOps & Registry

- [ ] ArgoCD (continuous reconciliation from this repo)
- [ ] Migrate platform components from install scripts to Argo apps
- [ ] Private chart/OCI registry — supersedes chart vendoring, see
      [ADR 0004](decisions/0004-vendor-helm-charts.md). Harbor (full:
      replication, scanning, RBAC, cosign) or Zot/registry:2
      (lightweight pull-through) for the mechanics.
- [ ] Mirror container images into the registry — closes the second of
      the three external deps ADR 0004 names (charts done, images here,
      Grafana GNet dashboards still open). `skopeo copy` / `crane copy`
      upstream→private, then rewrite chart image refs via values
      (`image.registry` / `global.imageRegistry`) to point at it.
      Removes the docker.io rate-limit + repo-availability dependency
      at pod-pull time. Mirrors the work ECR pattern.
- [ ] (pairs with Layer 4) cosign-sign mirrored images + Kyverno
      verify-signature admission — completes require-digest into
      require-signed-by-our-pipeline
- [ ] Jenkins as a deploy-and-operate lab component (Helm chart,
      persistence, agents, Jenkinsfile, in-cluster builds e.g. kaniko) —
      learn to OPERATE CI/CD, not as the repo's gate (that's Actions).
      Mirrors the work environment; optionally run a pipeline parallel
      to the Actions gate to compare.

## Layer 4: Security

- [ ] Falco (runtime detection)
- [ ] Kyverno (admission policies) — audit mode first, then enforce:
      require image digests, require PDB on multi-replica workloads,
      require non-default ServiceAccounts, require non-root security
      contexts, require resource requests (cpu + memory) and memory
      limits — deliberately NOT cpu limits (throttling trade-off is a
      per-workload call, not a cluster rule)
- [ ] Trivy (image + manifest scanning)
- [ ] Falco-detection scenario documented

## Layer 5: Secrets & Networking

- [ ] Vault (dev mode)
- [ ] External Secrets Operator
- [ ] Grafana admin credential via ESO + Vault (closes the Layer-2
      tracked deferral; same pattern for any chart taking credentials)
- [ ] Cilium (replace default CNI)
- [ ] NetworkPolicies (first enforced ones — verify the CNI enforces)
- [ ] Hubble UI for network observability

## Layer 6: Stateful Workloads & Real HA

- [ ] Patroni (Postgres HA)
- [ ] Strimzi (Kafka)
- [ ] Redis Sentinel
- [ ] topologySpreadConstraints + quorum-style PDBs (minAvailable) for
      the stateful sets above (tracked deferral from Layer 1)
- [ ] Have the stateful charts consume the shared **`charts/common`**
      library (built with podinfo): `common.pdb` (use quorum-style
      `minAvailable` for these) + `common.topologySpreadConstraints`
      with `whenUnsatisfiable: DoNotSchedule` (hard spread — quorum
      systems must not co-locate). Selector comes from the shared
      `selectorLabels` helper, so it can't drift. Kyverno (Layer 4)
      enforces *presence* on multi-replica workloads; the library makes
      compliance the path of least resistance.
- [ ] Chaos Mesh
- [ ] Tempo (traces) + a real traced application (moved from Layer 2)
- [ ] Postgres failover scenario documented
- [ ] Kafka broker-loss scenario documented

## External access (zero-trust, capstone milestone)

Expose select services (Grafana, etc.) to other machines/networks
behind an unbypassable identity-aware proxy. Depends on Ingress/TLS
(2.5) and Secrets/identity (Layer 5); lands after the core services
exist. The governing principle: **auth must be unbypassable** — every
layer assumes the one in front could fail (the opposite of an
app-enforcing-its-own-SSO setup, which a single app-level query param
can sidestep).

- [ ] Cloudflare Tunnel for ingress — outbound-only, **no open inbound
      ports, no home-IP exposure**; TLS terminated at the edge
- [ ] Cloudflare Access enforcing Google/Microsoft SSO **+ MFA** at the
      edge, restricted to an **explicit identity allowlist** (never
      "anyone with a Google account")
- [ ] Backends stay loopback/ClusterIP-bound (never NodePort/0.0.0.0) —
      this is what makes the proxy the only door
- [ ] Harden apps behind the gate: anonymous access off, native login
      form disabled, app trusts the proxy's identity (e.g. Grafana
      auth.proxy/JWT) instead of running its own login
- [ ] OAuth client secret + tunnel token in Vault, synced via ESO
      (Layer 5) — never in a config file
- [ ] Self-hosted forward-auth (oauth2-proxy / Authentik) done
      separately as the Layer-5 internal identity exercise (enterprise
      datacenter pattern; learning value)
- [ ] Optional: Tailscale mesh as a lower-risk admin path for own
      devices (nothing public on that path at all)

## Operations runbooks & drills (after most infra is in place)

Best done near the END of the build — once the full stack exists,
there's far more to investigate (real components, throttling, noisy
neighbors) and the drills are realistic instead of contrived. Each
written from an actual hands-on session (manufacture the condition,
investigate live, document what you saw — the node-failure runbook is
the template).

- [ ] "Investigating high CPU" — load-test/stress a workload (e.g.
      podinfo), then diagnose via Prometheus/Grafana: which pod, real
      load vs CFS throttling (`container_cpu_cfs_throttled_*`),
      resolution (scale / fix / right-size). Exercises metrics-server,
      the vendored dashboards, the cpu-limit/throttling concept, and
      right-sizing end-to-end.
- [ ] Further drills as components land (e.g. "investigating high
      memory / OOMKills", "tracing a slow request" once Tempo exists,
      "log spelunking" once Loki exists).

## Repo tooling (layer-independent)

- [x] Tier-1 CI gate on **GitHub Actions** (`.github/workflows/ci.yml`):
      shellcheck, yamllint, kubeconform, helm-template smoke, chart
      checksum verify, gitleaks secret scan. Static only — no cluster.
- [ ] GitHub push protection (repo setting) — pairs with the gitleaks
      job; .gitignore is only a soft guard (git add -f bypasses it, and
      it does nothing for already-committed files)
- [ ] Tier-2 integration CI (spin up kind, install charts, assert
      healthy) — deferred until the install flow is proven manually
- [ ] Pin Actions to commit SHAs (supply-chain hardening, Layer-4 ethos)

CI engine = GitHub Actions (native to a public GitHub repo, zero infra).
CD = Argo CD (Layer 3.5). Jenkins is NOT the repo's gate — it's planned
as a deploy-and-operate lab component (below) to learn CI/CD ops, since
it mirrors the work environment.
