# Roadmap

The lab is built in layers. Each layer adds a concrete capability and gets
documented as it lands.

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

- [ ] kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
- [ ] Loki (logs)
- [ ] Tempo (traces)
- [ ] First runbook: "investigating high CPU"

## Layer 3: Backup & DR

- [ ] MinIO as S3 target
- [ ] Velero install
- [ ] Velero restore scenario documented
- [ ] etcd snapshot/restore drill

## Layer 4: Security

- [ ] Falco (runtime detection)
- [ ] Kyverno (admission policies)
- [ ] Trivy (image + manifest scanning)
- [ ] Falco-detection scenario documented

## Layer 5: Secrets & Networking

- [ ] Vault (dev mode)
- [ ] External Secrets Operator
- [ ] Cilium (replace default CNI)
- [ ] Hubble UI for network observability

## Layer 6: Stateful Workloads & Real HA

- [ ] Patroni (Postgres HA)
- [ ] Strimzi (Kafka)
- [ ] Redis Sentinel
- [ ] Chaos Mesh
- [ ] Postgres failover scenario documented
- [ ] Kafka broker-loss scenario documented
