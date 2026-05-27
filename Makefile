.DEFAULT_GOAL := help
.PHONY: help cluster-up cluster-down

# Make targets wrap multi-step orchestration only. Day-to-day inspection
# (get pods, logs, port-forward, etc.) is done with kubectl/k9s directly
# to build muscle memory that transfers to real clusters.

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

cluster-up: ## Create the local kind cluster
	./scripts/create-cluster.sh

cluster-down: ## Delete the local kind cluster
	./scripts/delete-cluster.sh
