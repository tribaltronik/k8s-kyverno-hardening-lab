#!/usr/bin/env bash
set -euo pipefail

echo "=== Testing privileged pod (DENY expected) ==="
kubectl apply -f workloads/privileged-pod.yaml || echo "Denied as expected"

echo "=== Testing insecure pod (DENY expected) ==="
kubectl apply -f workloads/insecure-pod.yaml || echo "Denied as expected"

echo "=== Testing secure pod (ALLOW expected) ==="
kubectl apply -f workloads/secure-pod.yaml || echo "Unexpected failure"

echo "=== Testing latest tag pod (DENY expected) ==="
kubectl apply -f workloads/latest-pod.yaml || echo "Denied as expected"

echo "=== Testing versioned pod (ALLOW expected) ==="
kubectl apply -f workloads/versioned-pod.yaml || echo "Unexpected failure"

echo "=== Testing no-resources pod (DENY expected) ==="
kubectl apply -f workloads/no-resources-pod.yaml || echo "Denied as expected"

echo "=== Testing resources pod (ALLOW expected) ==="
kubectl apply -f workloads/resources-pod.yaml || echo "Unexpected failure"

echo "=== Testing bad registry pod (DENY expected) ==="
kubectl apply -f workloads/bad-registry-pod.yaml || echo "Denied as expected"

echo "=== Test suite complete ==="