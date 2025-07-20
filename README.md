# Dogfooding Kubernetes Environment

This repository provides a local Kubernetes "dogfooding" environment using [Kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/) for development and testing. It leverages [ArgoCD](https://argo-cd.readthedocs.io/) for GitOps-style application deployment and includes monitoring tools like [Goldpinger](https://github.com/bloomberg/goldpinger).

## 🏗️ Architecture

This repository sets up a multi-node Kubernetes cluster with:

- **Kind Cluster**: 1 control-plane + 1 worker node
- **ArgoCD**: GitOps deployment tool for managing applications
- **Podinfo**: Demo application showcasing Kubernetes features
- **Port Forwarding**: Services exposed on localhost:30080 and localhost:30081

## 📁 Repository Structure

```
dogfooding-k8s/
├── argocd/                    # ArgoCD configuration
│   ├── apps/                  # ArgoCD Application manifests
│   ├── charts/                # Helm charts
│   ├── kustomization.yaml     # ArgoCD Helm chart config
│   └── values.yaml           # ArgoCD Helm values
├── default/                   # Default namespace applications
│   ├── goldpinger.yaml       # Network monitoring tool
│   ├── debug.yaml            # Network debugging pod
│   └── kustomization.yaml    # Default namespace resources
├── kind-config.yaml          # Kind cluster configuration
├── Makefile                  # Automation scripts
└── README.md                # This file
```

## 🚀 Quick Start

### Prerequisites

Install the following tools:
- [kustomize](https://kubectl.docs.kubernetes.io/installation/kustomize/)
- [kind](https://kind.sigs.k8s.io/)
- [helm](https://helm.sh/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [k9s](https://k9scli.io/) (optional, for cluster visualization)

### Automated Setup

```bash
# Create cluster and deploy all applications
make init

# Delete cluster
make delete

# Apply manifests to existing cluster
make apply
```

### Manual Setup

```bash
# Create the cluster
kind create cluster --name cluster0-kind --config kind-config.yaml

# Verify cluster is running
kubectl get nodes
kubectl get nodes -o yaml

# Deploy ArgoCD
kubectl create namespace argocd
kustomize build argocd --enable-helm | kubectl apply --server-side -f -

# Deploy ArgoCD applications
kubectl apply -k argocd/apps
```

## 🔧 Configuration Details

### Kind Cluster Configuration (`kind-config.yaml`)

- **Topology**: 1 control-plane + 1 worker node
- **Port Mappings**: 
  - `30080` → `30080` (TCP)
  - `30081` → `30081` (TCP)
- **Network**: Exposed on all interfaces (`0.0.0.0`)

### ArgoCD Setup

- **Version**: 7.8.26 (via Helm chart)
- **Namespace**: `argocd`
- **GitOps**: Self-managed applications
- **Sync Policy**: Automated with self-healing enabled

## 🔍 Accessing Services
- **ArgoCD UI:** After deployment, ArgoCD will be available on `localhost:30080` or `localhost:30081` (see `kind-config.yaml` for details).
- **Login:** Username is admin. Retrieve the password with: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- **Port Forwarding:** You can also use `kubectl port-forward` or access via NodePort services (ex: `kubectl port-forward -n default svc/goldpinger 8080:8080`).

### Direct Node Access

Services are exposed on the configured ports:
- **Port 30080**: Available on localhost:30080
- **Port 30081**: Available on localhost:30081

## 🛠️ Development Workflow

1. **Initial Setup**: Run `make init` for a fresh cluster
2. **Application Management**: ArgoCD manages applications via GitOps
3. Use kubectl, k9s, or the ArgoCD UI to monitor and manage resources.
4. **Cleanup**: Use `make delete` to tear down the cluster

## 🔗 Connecting to the Cluster & Kubeconfig

When you create a Kind cluster, it automatically updates your kubeconfig file (usually at `~/.kube/config`) to add a new context for the cluster.

### Kubeconfig Location
- By default, kubeconfig is located at `~/.kube/config`.
- Kind will merge the new cluster context into this file.

## Key Configuration Files
- `kind-config.yaml`: Cluster topology and port forwarding
- `argocd/kustomization.yaml`: Helm chart configuration for ArgoCD
- `argocd/values.yaml`: ArgoCD Helm values customization
- `argocd/apps/`: ArgoCD Application manifests
- `default/kustomization.yaml`: Default namespace resource definitions

### Debug Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check ArgoCD applications
kubectl get applications -n argocd

# Debug network connectivity
kubectl exec -it deployment/network-debug -- /bin/sh

# Check Goldpinger status
kubectl get pods -l app=goldpinger
kubectl logs -l app=goldpinger
```

## 📝 Notes
- The cluster uses Kind for local development
- ArgoCD manages its own deployment via GitOps
- All applications are configured with appropriate resource limits
- Network debugging tools are available for troubleshooting
- The setup is designed for learning and testing Kubernetes concepts

## 🐛 Troubleshooting

### Common Issues

**Cluster won't start:**
```bash
# Check Docker is running
docker ps

# Clean up existing clusters
kind delete cluster --name cluster0-kind
make init
```

**ArgoCD not accessible:**
```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Port forward ArgoCD server
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

**Applications not syncing:**
```bash
# Check application status
kubectl get applications -n argocd

# Force sync
kubectl patch app default -n argocd --type='merge' -p='{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

## 🎯 Demo Features with Podinfo

Podinfo is included as a demo application to showcase Kubernetes capabilities:

### Basic Kubernetes Concepts
```bash
# View deployment and replica sets
kubectl get deployments,replicasets,pods -l app.kubernetes.io/name=podinfo

# Scale deployment manually
kubectl scale deployment podinfo --replicas=5

# View service and endpoints
kubectl get svc,endpoints podinfo
```

### Horizontal Pod Autoscaler (HPA)
```bash
# Check HPA status
kubectl get hpa podinfo

# Generate load to trigger autoscaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
while true; do wget -q -O- http://podinfo:9898/; done
```

### Rolling Updates
```bash
# Update image version to trigger rolling update
kubectl set image deployment/podinfo podinfod=stefanprodan/podinfo:6.5.3

# Watch rolling update in progress
kubectl rollout status deployment/podinfo

# View rollout history
kubectl rollout history deployment/podinfo
```

### Health Checks and Monitoring
```bash
# Check health endpoints
curl localhost:30080/healthz
curl localhost:30080/readyz

# View metrics (Prometheus format)
curl localhost:30080/metrics

# Check resource usage
kubectl top pods -l app.kubernetes.io/name=podinfo
```