# k8s-kyverno-hardening-lab
This repository provides a fully automated, reproducible lab environment for exploring Kubernetes security hardening using Kyverno. It is designed for platform engineers, security architects, and consultants who want a minimal but realistic setup to test policy‑driven governance on Kubernetes.

flowchart TD

    subgraph DevMachine["Local Machine"]
        A[plan.md<br/>Repository Structure] --> B[scripts/<br/>Automation Scripts]
        A --> C[policies/<br/>Kyverno Policies]
        A --> D[workloads/<br/>Test Pods]
    end

    subgraph KindCluster["kind Cluster (Single Node)"]
        E[Kubernetes API Server]
        F[Kyverno Admission Controller]
        G[Kyverno Policies Applied]
        H[Workload Pods]
    end

    B -->|create-cluster.sh| KindCluster
    B -->|install-kyverno.sh| F
    B -->|apply-policies.sh| G
    B -->|test-all.sh| H

    C --> G
    D --> H

    F -->|Validates / Mutates| H
    G -->|Enforces Security Rules| H
