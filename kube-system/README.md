# kube-system

This directory is intended for Kubernetes system-level components and configurations that should be deployed to the `kube-system` namespace.

## Purpose

The `kube-system` namespace is reserved for Kubernetes system components. This directory can contain manifests for:

- **CNI plugins** - Custom network configurations
- **DNS configurations** - CoreDNS customizations
- **Metrics server** - Resource usage monitoring
- **System controllers** - Custom operators or controllers
- **Storage classes** - Persistent volume configurations
- **Ingress controllers** - Traffic routing components

## Usage

To deploy manifests from this directory:

```bash
# Apply all manifests in kube-system namespace
kubectl apply -f kube-system/ --namespace=kube-system

# Or using kustomize (if kustomization.yaml exists)
kubectl apply -k kube-system/
```

## Notes

- Components in `kube-system` typically require elevated privileges
- System components should be carefully tested before deployment
- Some components may require specific RBAC permissions
- Consider using Helm charts for complex system components