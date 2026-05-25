# 0002: Use kind over k3d

## Status

Accepted — 2026-05-26

## Context

The lab needs a local Kubernetes cluster to host every other component.
The cluster will be used long-term, broken on purpose, and rebuilt
frequently.

Alternatives considered:

- **minikube** — slow on M1, single-node by default, dated UX.
- **Docker Desktop Kubernetes** — tied to Docker Desktop, single-node,
  limited config.
- **kind** — runs upstream Kubernetes nodes as Docker containers. Backed
  by Kubernetes SIG. Multi-node out of the box. Slightly slower boot
  than k3d.
- **k3d** — runs k3s (lightweight, CNCF-certified Kubernetes) as Docker
  containers. Faster boot, smaller RAM, but ships with k3s-specific
  defaults (Traefik, klipper-lb, local-path provisioner, SQLite-backed
  etcd in single-node mode).

The lab is intended to mirror production-style Kubernetes (the kind run
on EKS / GKE / AKS) so that mental models built here transfer cleanly.

## Decision

Use **kind** for the local cluster.

## Consequences

- ➕ Runs upstream/vanilla Kubernetes — closer parity to managed clusters
  in production environments.
- ➕ Multi-node clusters trivially (1 control plane + N workers).
- ➕ No bundled ingress controller, LB, or storage class — forces an
  explicit install of each, which is a learning positive.
- ➕ Killing a node is a `docker stop` away — great for chaos exercises.
- ➖ Slower boot than k3d (~30 s vs ~15 s). Acceptable for a long-lived
  cluster.
- ➖ Heavier RAM per node than k3d (~500 MB vs ~200 MB). Still
  comfortable on a 32 GB machine.
- ➖ More tools to install separately (ingress, LB, storage) — extra
  steps in Layer 1 / Layer 2.

## Notes

k3d would be the better pick for "I want a cluster in 15 seconds for an
ad-hoc test." A separate k3d cluster can always be spun up alongside the
main lab if needed.
