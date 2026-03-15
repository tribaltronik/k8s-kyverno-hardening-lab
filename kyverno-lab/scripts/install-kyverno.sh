#!/usr/bin/env bash
set -euo pipefail

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace

kubectl wait --for=condition=Available deployment/kyverno -n kyverno --timeout=180s
kubectl get pods -n kyverno