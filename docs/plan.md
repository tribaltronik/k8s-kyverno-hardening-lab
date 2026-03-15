# Kyverno Hardening Lab – Implementation Plan (for Coding Agent)

This document defines the complete step‑by‑step plan for implementing a local Kubernetes security‑hardening lab using **kind** and **Kyverno**.
The coding agent must follow each phase in order and complete every checklist item exactly as written.

---

# Phase 1 — Repository Setup

## Goal

Create the directory structure and prepare the workspace.

## Checklist

- [x] Create root folder `kyverno-lab`
- [x] Inside it, create subdirectories:
  - [x] `scripts/`
  - [x] `policies/`
  - [x] `workloads/`
- [x] Ensure all directories are empty and ready for file creation

---

# Phase 2 — Create Cluster Definition

## Goal

Provide a minimal single‑node kind cluster configuration.

## Checklist

- [x] Create file `kyverno-lab/kind-cluster.yaml`
- [x] Insert the following content exactly:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kyverno-lab
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: ClusterConfiguration
        apiServer:
          extraArgs:
            enable-admission-plugins: NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota
```

---

# Phase 3 — Create Automation Scripts

All scripts must be created under `kyverno-lab/scripts/` and made executable.

## 3.1 Create create-cluster.sh

### Checklist

- [x] Create file `scripts/create-cluster.sh`

- [x] Add:

```bash
#!/usr/bin/env bash
set -euo pipefail

kind create cluster --config kind-cluster.yaml

kubectl wait --for=condition=Ready node --all --timeout=120s
kubectl get nodes -o wide
```

## 3.2 Create delete-cluster.sh

### Checklist

- [x] Create file `scripts/delete-cluster.sh`

- [x] Add:

```bash
#!/usr/bin/env bash
set -euo pipefail

kind delete cluster --name kyverno-lab
```

## 3.3 Create install-kyverno.sh

### Checklist

- [x] Create file `scripts/install-kyverno.sh`

- [x] Add:

```bash
#!/usr/bin/env bash
set -euo pipefail

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace

kubectl wait --for=condition=Available deployment/kyverno -n kyverno --timeout=180s
kubectl get pods -n kyverno
```

## 3.4 Create apply-policies.sh

### Checklist

- [x] Create file `scripts/apply-policies.sh`

- [x] Add:

```bash
#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f policies/pss-restricted.yaml
kubectl apply -f policies/cpol-require-secure-context.yaml
kubectl apply -f policies/cpol-disallow-latest.yaml
kubectl apply -f policies/cpol-require-resources.yaml
kubectl apply -f policies/cpol-restrict-image-registries.yaml

echo "Waiting for policies to propagate..."
sleep 10
```

## 3.5 Create test-all.sh

### Checklist

- [x] Create file `scripts/test-all.sh`

- [x] Add:

```bash
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
```

---

# Phase 4 — Create Kyverno Policies

## 4.1 Pod Security Standards (Restricted)

### Checklist

- [x] Download file from:

  `https://raw.githubusercontent.com/kyverno/policies/main/other/apply-pss-restricted-profile/apply-pss-restricted-profile.yaml`

- [x] Save as `policies/pss-restricted.yaml`

## 4.2 Create cpol-require-secure-context.yaml

### Checklist

- [x] Create file `policies/cpol-require-secure-context.yaml`

- [x] Insert exact content:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-secure-context
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: require-non-root-and-readonly
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Containers must run as non-root and with readOnlyRootFilesystem=true."
        pattern:
          spec:
            securityContext:
              runAsNonRoot: true
            containers:
              - name: "*"
                securityContext:
                  readOnlyRootFilesystem: true
```

## 4.3 Create cpol-disallow-latest.yaml

### Checklist

- [x] Create file `policies/cpol-disallow-latest.yaml`

- [x] Insert:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: block-latest-tag
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Using the 'latest' tag is not allowed. Use an explicit version."
        pattern:
          spec:
            containers:
              - name: "*"
                image: "!*:latest"
```

## 4.4 Create cpol-require-resources.yaml

### Checklist

- [x] Create file `policies/cpol-require-resources.yaml`

- [x] Insert:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resources
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: require-requests-limits
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "All containers must have CPU and memory requests/limits."
        pattern:
          spec:
            containers:
              - name: "*"
                resources:
                  requests:
                    cpu: "?*"
                    memory: "?*"
                  limits:
                    cpu: "?*"
                    memory: "?*"
```

## 4.5 Create cpol-restrict-image-registries.yaml

### Checklist

- [x] Create file `policies/cpol-restrict-image-registries.yaml`

- [x] Insert:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: restrict-image-registries
spec:
  validationFailureAction: Enforce
  background: true
  rules:
    - name: only-allow-dockerhub-and-ghcr
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Images must come from docker.io or ghcr.io."
        pattern:
          spec:
            containers:
              - name: "*"
                image: "docker.io/* | ghcr.io/*"
```

---

# Phase 5 — Create Workload Manifests

Each file must be created under `kyverno-lab/workloads/`.

## Checklist

- [ ] `workloads/privileged-pod.yaml`
- [ ] `workloads/insecure-pod.yaml`
- [ ] `workloads/secure-pod.yaml`
- [ ] `workloads/latest-pod.yaml`
- [ ] `workloads/versioned-pod.yaml`
- [ ] `workloads/no-resources-pod.yaml`
- [ ] `workloads/resources-pod.yaml`
- [ ] `workloads/bad-registry-pod.yaml`

(Each file contains the exact YAML previously defined.)

---

# Phase 6 — Create README.md

## Checklist

- [ ] Create file `README.md`

- [ ] Include:
  - Overview of the lab
  - Prerequisites
  - Quick start commands
  - How to inspect results
  - Cleanup instructions

---

# Phase 7 — Validation

## Checklist

- [ ] Run `scripts/create-cluster.sh`
- [ ] Run `scripts/install-kyverno.sh`
- [ ] Run `scripts/apply-policies.sh`
- [ ] Run `scripts/test-all.sh`
- [ ] Confirm:
  - **DENY**: privileged, insecure, latest, no-resources, bad-registry
  - **ALLOW**: secure, versioned, resources
- [ ] Run `scripts/delete-cluster.sh`

---

# Completion Criteria

The implementation is complete when:

- All files exist with exact content
- All scripts run without modification
- Policies enforce expected behavior
- Workload tests produce correct ALLOW/DENY outcomes
- Cluster can be created and destroyed cleanly

---

If you want, I can also generate:

- A **Makefile**
- A **CI pipeline**
- A **shift‑left Kyverno CLI workflow**
- A **diagram** of the architecture

Just say the word and I'll extend this single‑file plan.