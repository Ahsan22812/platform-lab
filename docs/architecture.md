# Architecture

> High-level description of what the lab is, how the pieces fit, and the
> reasoning behind major choices. Updated as the lab evolves.

## Overview

A single local Kubernetes cluster running on the workstation, layered with
platform components (observability, security, GitOps, backup, etc.) and
sample workloads. Failure scenarios document how the cluster behaves under
stress.

## Components

- **Runtime**: Colima (container runtime on macOS)
- **Cluster**: kind (1 control plane + 2 workers)
- **Platform**: ingress, observability, GitOps, security, backup, storage,
  secrets, networking — installed incrementally
- **Workloads**: starts with `podinfo`, grows to Postgres HA / Kafka / Redis
- **Scenarios**: documented failure exercises

## Diagram

_TODO: add diagram once more components are in place._

## Design principles

- **Reproducible**: everything in git, single command to rebuild
- **Honest**: empty/planned folders are marked "not yet implemented"
- **Documented**: every non-obvious choice gets an ADR in `docs/decisions/`
- **Failure-focused**: scenarios are first-class, not afterthoughts
