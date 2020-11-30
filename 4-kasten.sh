#!/usr/bin/env bash

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
fi

helm repo add kasten https://charts.kasten.io/
helm repo update
kubectl create namespace kasten-io
helm install k10 kasten/k10 --namespace=kasten-io

kubectl annotate volumesnapshotclass csi-hostpath-snapclass \
    k10.kasten.io/is-snapshot-class=true

#Wordpress/MySQL backup
kubectl --namespace kasten-io apply -f \
    https://raw.githubusercontent.com/kanisterio/kanister/0.43.0/examples/stable/mysql/mysql-blueprint.yaml
kubectl --namespace wordpress annotate deployment/mysql \
    kanister.kasten.io/blueprint=mysql-blueprint

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Confirm wordpress kasten is running with kubectl get pods --namespace kasten-io"
echo "kubectl --namespace kasten-io port-forward --address 0.0.0.0 service/gateway 8080:8000"
echo "Open your browser https://your Kind host ip(Ubuntu IP):8080/k10/#/"
