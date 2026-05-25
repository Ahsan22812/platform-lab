.PHONY: help cluster-up cluster-down cluster-status

CLUSTER_NAME ?= platform-lab
KIND_CONFIG  ?= clusters/kind/kind-config.yaml

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

cluster-up: ## Create the local kind cluster
	./scripts/create-cluster.sh

cluster-down: ## Delete the local kind cluster
	./scripts/delete-cluster.sh

cluster-status: ## Show cluster nodes
	kubectl get nodes -o wide
