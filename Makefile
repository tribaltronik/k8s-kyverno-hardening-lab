.PHONY: help setup create-cluster install-kyverno apply-policies test clean

help:
	@echo "Kyverno Hardening Lab - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  setup         - Full setup: create cluster, install Kyverno, apply policies"
	@echo "  create-cluster - Create kind cluster"
	@echo "  install-kyverno - Install Kyverno via Helm"
	@echo "  apply-policies - Apply Kyverno policies"
	@echo "  test          - Run all workload tests"
	@echo "  clean         - Delete kind cluster"

setup: create-cluster install-kyverno apply-policies
	@echo "=== Lab setup complete ==="

create-cluster:
	@echo "=== Creating kind cluster ==="
	cd kyverno-lab && kind create cluster --config kind-cluster.yaml
	kubectl wait --for=condition=Ready node --all --timeout=120s
	kubectl get nodes -o wide

install-kyverno:
	@echo "=== Installing Kyverno ==="
	helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
	helm repo update
	helm upgrade --install kyverno kyverno/kyverno \
		--namespace kyverno \
		--create-namespace
	kubectl wait --for=condition=Available deployment/kyverno -n kyverno --timeout=180s
	kubectl get pods -n kyverno

apply-policies:
	@echo "=== Applying Kyverno policies ==="
	cd kyverno-lab && kubectl apply -f policies/pss-restricted.yaml
	cd kyverno-lab && kubectl apply -f policies/cpol-require-secure-context.yaml
	cd kyverno-lab && kubectl apply -f policies/cpol-disallow-latest.yaml
	cd kyverno-lab && kubectl apply -f policies/cpol-require-resources.yaml
	cd kyverno-lab && kubectl apply -f policies/cpol-restrict-image-registries.yaml
	@echo "Waiting for policies to propagate..."
	sleep 10

test:
	@echo "=== Running workload tests ==="
	cd kyverno-lab && ./scripts/test-all.sh

clean:
	@echo "=== Deleting kind cluster ==="
	kind delete cluster --name kyverno-lab