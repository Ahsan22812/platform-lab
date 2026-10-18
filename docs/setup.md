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
colima start --cpu 8 --memory 24 --disk 100
```

Sizing grows with the lab. Layer 1–2 alone runs fine on `--memory 8`;
`--memory 16` covers through the CI/CD platform (Argo CD + Harbor) and
into EFK; the figures above run the **entire** roadmap concurrently
(Elasticsearch, Kafka, Patroni — the JVM/data components — are what
drive memory up). Scale to your machine: keep Colima at ≤ ~70% of
physical RAM so macOS keeps headroom. Resize any time with
`colima stop && colima start --cpu N --memory N` (the kind cluster
survives the restart).

## Tune the VM kernel (required)

Two classes of workload need raised kernel limits on the VM's Linux,
applied via Colima's `provision` block so they survive every reboot.
Without them, log shippers (Fluent Bit) CrashLoop with inotify
"too many open files", and Elasticsearch (EFK) refuses to start.

Edit `~/.colima/default/colima.yaml` — replace `provision: null` with:

```yaml
provision:
  - mode: system
    script: |
      # Raise inotify limits — kind/Colima defaults are low and shared
      # across the cluster, so log shippers (Fluent Bit) hit "too many
      # open files".
      sysctl -w fs.inotify.max_user_instances=512
      sysctl -w fs.inotify.max_user_watches=524288
      # Elasticsearch (EFK) refuses to start below this. Harmless to
      # set early; pre-staged so EFK works out of the box.
      sysctl -w vm.max_map_count=262144
```

Then apply and verify:

```bash
colima stop && colima start
colima ssh -- sudo sysctl fs.inotify.max_user_instances fs.inotify.max_user_watches vm.max_map_count
# expect: 512 / 524288 / 262144
```

This mirrors what cloud node tuning does via userData/custom AMIs —
node-level config stays at the VM layer so the charts remain
production-clean (they assume tuned nodes, as managed clusters provide).

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
