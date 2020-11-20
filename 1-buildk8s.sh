#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

# Install Kind
if [ ! -f /usr/local/bin/kind ]; then
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.9.0/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/kind
kind completion bash > /etc/bash_completion.d/kind
source /etc/bash_completion.d/kind
fi

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt -y install docker.io apt-transport-https gnupg2 curl
systemctl enable --now docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt update
apt -y install kubectl
apt clean
kubectl completion bash >/etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
echo 'export KUBE_EDITOR=vi' >>~/.bashrc
fi

# Install Helm
if [ ! -f /usr/local/bin/helm ]; then
curl -O https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
bash ./get-helm-3
helm version
rm get-helm-3
helm completion bash > /etc/bash_completion.d/helm
source /etc/bash_completion.d/helm
fi

# Bulding Kind Cluster
kind create cluster --name k10-demo --image kindest/node:v1.18.2 --wait 600s
kind get kubeconfig > kubeconfig.yaml

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "There is no action."
