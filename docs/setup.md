# Setup

How to bring this lab up on a fresh machine.

## Prerequisites

- macOS (Apple Silicon or Intel) or Linux
- Homebrew (or equivalent package manager)
- ~12 GB free RAM available for the VM
- ~40 GB free disk space

## Tools

Install the base toolchain:

```bash
brew install colima kind kubectl helm k9s kubectx stern
```

## Start the container runtime

```bash
colima start --cpu 6 --memory 16 --disk 100
```

Sizing grows with the lab. Layer 1–2 alone runs fine on `--memory 8`;
the figures above cover through the CI/CD platform (Argo CD + Harbor)
and into EFK. The heavy, JVM/data components (Elasticsearch, Kafka,
Patroni) are what drive memory up — bump toward `--memory 20` if you
run them all at once. Keep Colima at ≤ ~70% of physical RAM so macOS
keeps headroom. Resize any time with `colima stop && colima start
--cpu N --memory N` (the kind cluster survives the restart).

## Create the cluster

```bash
make cluster-up
```

## Point your shell at the lab

The lab's credentials live in a **dedicated kubeconfig**
(`~/.kube/platform-lab.yaml`), not in `~/.kube/config`. In every shell
where you work on the lab:

```bash
export KUBECONFIG=~/.kube/platform-lab.yaml
```

Why: if the default kubeconfig on your machine points at other clusters
(work, cloud), keeping the lab in its own file makes it impossible to
run a lab command against them, or vice versa — isolation by file, not
by discipline. Shells without the export never see the lab at all.

To use a different location, set `PLATFORM_LAB_KUBECONFIG` before
running the scripts.

## Tear down

```bash
make cluster-down
```

## Verify

```bash
kubectl get nodes
```

Should show 3 nodes (`platform-lab-control-plane`, `platform-lab-worker`,
`platform-lab-worker2`) in `Ready` state.
