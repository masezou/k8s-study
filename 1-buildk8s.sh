#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

# Install Kind
if [ ! -f /usr/local/bin/kind ]; then
curl -s -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
kind completion bash > /etc/bash_completion.d/kind
source /etc/bash_completion.d/kind
fi

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt update
apt -y install docker.io apt-transport-https gnupg2 curl
systemctl enable --now docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt update
apt -y install kubectl
kubectl completion bash >/etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
echo 'export KUBE_EDITOR=vi' >>~/.bashrc
fi

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

# Bulding Kind Cluster
kind create cluster --name k10-demo --image kindest/node:v1.18.15 --wait 600s
#kind create cluster --config multi-node.yaml --name k10-demo --image kindest/node:v1.18.2 --wait 600s
#kind get kubeconfig --name k10-demo  > ~/kubeconfig-k10-demo.yaml
#kind create cluster --config multi-node.yaml --name k10-demo-dr --image kindest/node:v1.18.2 --wait 600s
#kind get kubeconfig --name k10-demo-dr  > ~/kubeconfig-k10-demo-dr.yaml

#kubectl config use-context kind-k10-demo
kubectl config get-contexts

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "There is no action."
