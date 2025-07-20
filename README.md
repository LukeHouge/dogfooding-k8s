# dogfooding-k8s
- install kustomize
- install kind
- install helm
- install kubectl

- run `kind create cluster --name lukes-mbp --config kind-config.yaml`
- `kubectl get nodes`
- `kubectl get nodes -o yaml`

- connect with k9s or whatever tool (or just use kubectl)
- kind will auto generate a `~/.kube/config` to connect to cluster
- then you can view pods, apps, deployments, services, etc.
- can port forward in services