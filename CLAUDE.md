# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Kubernetes dogfooding environment using Kind (Kubernetes in Docker) for local development and testing. The repository sets up a local Kubernetes cluster with ArgoCD for GitOps-style application deployment and includes monitoring tools like Goldpinger.

## Architecture

### Cluster Setup
- **Kind cluster**: Multi-node setup with one control-plane and one worker node
- **Port mappings**: Exposes services on localhost:30080 and localhost:30081
- **ArgoCD**: GitOps deployment tool for managing applications
- **Goldpinger**: Network connectivity monitoring tool

### Directory Structure
- `argocd/`: ArgoCD Helm chart configuration and application definitions
- `default/`: Default namespace applications (Goldpinger, debug tools)
- `kind-config.yaml`: Kind cluster configuration with port mappings
- `Makefile`: Automation for cluster lifecycle and deployments

## Common Commands

### Cluster Management
```bash
# Create cluster and deploy applications
make init

# Delete cluster
make delete

# Apply manifests to existing cluster
make apply
```

### Manual Setup (Alternative)
```bash
# Create cluster
kind create cluster --name lukes-mbp --config kind-config.yaml

# Verify cluster
kubectl get nodes

# Connect with k9s or kubectl (kubeconfig auto-generated at ~/.kube/config)
```

### Application Management
```bash
# Deploy ArgoCD
kubectl create namespace argocd
kustomize build argocd --enable-helm | kubectl apply --server-side -f -

# Deploy ArgoCD applications
kubectl apply -k argocd/apps
```

## Key Configuration Files

- `kind-config.yaml`: Defines cluster topology and port forwarding
- `argocd/kustomization.yaml`: Helm chart configuration for ArgoCD v7.8.26
- `argocd/values.yaml`: ArgoCD Helm values customization
- `argocd/apps/`: ArgoCD Application manifests for GitOps deployment
- `default/kustomization.yaml`: Default namespace resource definitions

## Development Workflow

1. Use `make init` to create a fresh cluster with all applications
2. ArgoCD will be available after deployment (check README for login credentials)
3. Use port forwarding or NodePort services on ports 30080/30081 for access
4. Applications are managed via GitOps through ArgoCD applications in `argocd/apps/`

## Prerequisites

Ensure these tools are installed:
- kustomize
- kind
- helm
- kubectl
- k9s (optional, for cluster visualization)