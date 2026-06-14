# platform-lab

Personal infrastructure lab for hands-on practice with HA, DR, observability,
and security on Kubernetes.

## What's in here

| Path | Purpose |
|---|---|
| `clusters/` | Cluster definitions (currently: local `kind` cluster) |
| `scripts/` | Helpers to create/destroy the lab cluster |
| `platform/` | Cluster-wide platform components (observability, security, etc.) |
| `apps/` | Application **source code** for our own services (code + Dockerfile) |
| `charts/` | Helm charts — the shared `common` library + per-service deployment charts |
| `scenarios/` | Documented failure and recovery exercises |
| `docs/` | Architecture, setup, runbooks, decision records (ADRs) |

## Current state

| Layer | Focus | Status |
|---|---|---|
| 1 | Foundation (kind cluster, podinfo, node-failure runbook) | ✅ done |
| 2 | Observability (Prometheus, Grafana, Loki) | 🔨 in progress |
| 2.5 | Ingress & TLS (ingress-nginx, cert-manager) | planned |
| 3 | Backup, DR & storage (Velero, MinIO, Thanos) | planned |
| 3.5 | GitOps & registry (ArgoCD) | planned |
| 4 | Security (Falco, Kyverno, Trivy) | planned |
| 5 | Secrets & networking (Vault, ESO, Cilium) | planned |
| 6 | Stateful HA (Patroni, Kafka, Redis, Chaos Mesh) | planned |

Status here is per-layer only; the item-level checklists live in
[`docs/roadmap.md`](docs/roadmap.md) — the single source of truth for
the plan.

## Getting started

See [`docs/setup.md`](docs/setup.md).

## Architecture decisions

See [`docs/decisions/`](docs/decisions/).
