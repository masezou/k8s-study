#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi
LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
# Install Kind
if [ ! -f /usr/local/bin/kind ]; then
apt -y install docker.io
curl -s -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.11.1/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
kind completion bash > /etc/bash_completion.d/kind
source /etc/bash_completion.d/kind
fi

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt update
apt -y install apt-transport-https gnupg2 curl
systemctl enable --now docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt update
#apt -y install kubectl
apt-get install kubectl=1.19.11-00
apt-mark hold kubectl
kubectl completion bash >/etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
echo 'export KUBE_EDITOR=vi' >>~/.bashrc
fi

# Install kubectx and kubens
if [ ! -f /usr/local/bin/kubectx ]; then
curl -OL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX}/kubectx_v${KUBECTX}_linux_x86_64.tar.gz
tar xfz kubectx_v${KUBECTX}_linux_x86_64.tar.gz
mv kubectx /usr/local/bin/
chmod +x /usr/local/bin/kubectx
rm -rf LICENSE kubectx_v${KUBECTX}_linux_x86_64.tar.gz
curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash
mv kubectx.bash /etc/bash_completion.d/
source /etc/bash_completion.d/kubectx.bash
curl -OL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX}/kubens_v${KUBECTX}_linux_x86_64.tar.gz
tar xfz kubens_v${KUBECTX}_linux_x86_64.tar.gz
mv kubens /usr/local/bin/
chmod +x /usr/local/bin/kubens
curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash
mv kubens.bash /etc/bash_completion.d/
source /etc/bash_completion.d/kubens.bash
rm -rf LICENSE kubens_v${KUBECTX}_linux_x86_64.tar.gz
apt -y install fzf
fi

# Install kubecolor
if [ ! -f /usr/bin/go ]; then
apt -y install golang-go
export GOPATH=$HOME/go
echo "export GOPATH=$HOME/go" >>/etc/profile
echo "export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin" >>/etc/profile
export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin
cd
fi
go get github.com/dty1er/kubecolor/cmd/kubecolor
echo "alias kubectl=kubecolor" >> /etc/profile
alias kubectl=kubecolor
#apt -y autoremove golang-go


# Install Helm
if [ ! -f /usr/local/bin/helm ]; then
curl -s -O https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
bash ./get-helm-3
helm version
rm get-helm-3
helm completion bash > /etc/bash_completion.d/helm
source /etc/bash_completion.d/helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
fi

# Install Skaffold
if [ ! -f /usr/local/bin/skaffold ]; then
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
install skaffold /usr/local/bin/
rm skaffold
skaffold completion bash >/etc/bash_completion.d/skaffold
source /etc/bash_completion.d/skaffold
fi

# Bulding Kind Cluster
if [ ! -f /usr/local/bin/kind ]; then
#kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.20.7 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.21.1 --wait 600s

cat <<EOF | kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  # WARNING: It is _strongly_ recommended that you keep this the default
  # (127.0.0.1) for security reasons. However it is possible to change this.
  apiServerAddress: "${LOCALIPADDR}"
  # By default the API server listens on a random open port.
  # You may choose a specific port but probably don't need to in most cases.
  # Using a random port makes it easier to spin up multiple clusters.
  apiServerPort: 6443
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

#Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

#kubectl config use-context kind-k10-demo
kubectl config get-contexts

#Install Metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
docker network inspect -f '{{.IPAM.Config}}' kind
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.200-172.18.255.250
EOF

# metric server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml

# Kuberntes Dashboard
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.5/aio/deploy/recommended.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}" > dashboard.token
echo "" >> dashboard.token
cat dashboard.token 

fi

# Expoert kubeconfig
kubectl config view --raw > Your_kubeconfig
echo "" >>Your_kubeconfig

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "you can access Kubernetes dashboard with kubectl poroxy"
echo "http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login"
