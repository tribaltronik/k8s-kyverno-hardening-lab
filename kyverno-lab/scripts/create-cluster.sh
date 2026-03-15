#!/usr/bin/env bash
set -euo pipefail

kind create cluster --config kind-cluster.yaml

kubectl wait --for=condition=Ready node --all --timeout=120s
kubectl get nodes -o wide