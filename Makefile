make init:
	kind create cluster --name cluster0-kind --config kind-config.yaml
	make apply
make delete:
	kind delete cluster --name cluster0-kind

make apply:
	# kubectl create namespace monitoring /
	# kustomize build monitoring --enable-helm | kubectl apply --server-side -f - || true
	kubectl create namespace argocd
	kustomize build argocd --enable-helm | kubectl apply --server-side -f -
	kubectl apply -k argocd/apps