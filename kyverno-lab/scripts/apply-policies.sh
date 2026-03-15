#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f policies/pss-restricted.yaml
kubectl apply -f policies/cpol-require-secure-context.yaml
kubectl apply -f policies/cpol-disallow-latest.yaml
kubectl apply -f policies/cpol-require-resources.yaml
kubectl apply -f policies/cpol-restrict-image-registries.yaml

echo "Waiting for policies to propagate..."
sleep 10