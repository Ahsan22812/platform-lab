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

- [ ] kube-prometheus-stack (Prometheus, Alertmanager; Grafana split out)
- [ ] Standalone Grafana (own chart, own upgrade cadence)
- [ ] Loki (logs)
- [ ] First runbook: "investigating high CPU"
- [ ] Right-size resource requests from observed usage (manual loop
      first — compare requests vs actual in Prometheus after a day of
      runtime; later consider VPA in recommendation mode + Goldilocks)

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

## Repo tooling (layer-independent)

- [ ] CI for lint + validate (shellcheck, yamllint/kubeconform,
      helm template smoke test, chart checksum verify) — engine TBD:
      GitHub Actions vs Jenkins vs both
- [ ] Secret scanning (gitleaks/trufflehog) in the pipeline + GitHub
      push protection — the real backstop for a public repo, since
      .gitignore is only a soft guard (git add -f bypasses it, and it
      does nothing for already-committed files)
