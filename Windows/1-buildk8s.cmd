

REM Bulding Kind Cluster
kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s
kind create cluster --name k10-demo --image kindest/node:v1.20.7 --wait 600s
kind create cluster --name k10-demo --image kindest/node:v1.21.1 --wait 600s

kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s --config=config.yml

REM Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s

REM kubectl config use-context kind-k10-demo
kubectl config get-contexts

REM Install Metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
kubectl apply -f metallb-config.yml

REM metric server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml

REM Kuberntes Dashboard
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.5/aio/deploy/recommended.yaml
kubectl apply -f dashboard-account.yml
kubectl apply -f dashboard-rbac.yml

kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" > dashboard.token
