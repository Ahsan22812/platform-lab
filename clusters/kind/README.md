# kind cluster

Local Kubernetes cluster for the lab, built with [kind](https://kind.sigs.k8s.io/).

- 1 control plane + 2 workers
- Created via `make cluster-up` (or `scripts/create-cluster.sh`)
- Destroyed via `make cluster-down` (or `scripts/delete-cluster.sh`)

Config: [`kind-config.yaml`](kind-config.yaml).
