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
colima start --cpu 4 --memory 8 --disk 40
```

## Create the cluster

```bash
make cluster-up
```

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
