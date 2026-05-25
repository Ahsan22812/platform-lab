# platform-lab

Personal infrastructure lab for hands-on practice with HA, DR, observability,
and security on Kubernetes.

## What's in here

| Path | Purpose |
|---|---|
| `clusters/` | Cluster definitions (currently: local `kind` cluster) |
| `scripts/` | Helpers to create/destroy the lab cluster |
| `platform/` | Cluster-wide platform components (observability, security, etc.) |
| `apps/` | Application workloads running on the platform |
| `scenarios/` | Documented failure and recovery exercises |
| `docs/` | Architecture, setup, runbooks, decision records (ADRs) |

## Current state

- [x] Repo scaffolded
- [ ] Local kind cluster
- [ ] Observability (Prometheus + Grafana)
- [ ] GitOps (ArgoCD)
- [ ] Backup & DR (Velero)
- [ ] Security (Falco, Kyverno, Trivy)
- [ ] Secrets (Vault, External Secrets Operator)
- [ ] Networking (Cilium)
- [ ] Stateful workloads (Postgres HA, Kafka)

See [`docs/roadmap.md`](docs/roadmap.md) for the full plan.

## Getting started

See [`docs/setup.md`](docs/setup.md).

## Architecture decisions

See [`docs/decisions/`](docs/decisions/).
