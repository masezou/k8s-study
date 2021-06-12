#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

KUBECTXARCH=linux_`arch`

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt update
apt -y install apt-transport-https gnupg2 curl
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
KUBECTX=0.9.3
curl -OL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX}/kubectx_v${KUBECTX}_${KUBECTXARCH}.tar.gz
tar xfz kubectx_v${KUBECTX}_${KUBECTXARCH}.tar.gz
mv kubectx /usr/local/bin/
chmod +x /usr/local/bin/kubectx
rm -rf LICENSE kubectx_v${KUBECTX}_${KUBECTXARCH}.tar.gz
curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash
mv kubectx.bash /etc/bash_completion.d/
source /etc/bash_completion.d/kubectx.bash
curl -OL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX}/kubens_v${KUBECTX}_${KUBECTXARCH}.tar.gz
tar xfz kubens_v${KUBECTX}_${KUBECTXARCH}.tar.gz
mv kubens /usr/local/bin/
chmod +x /usr/local/bin/kubens
curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash
mv kubens.bash /etc/bash_completion.d/
source /etc/bash_completion.d/kubens.bash
rm -rf LICENSE kubens_v${KUBECTX}_${KUBECTXARCH}.tar.gz
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
if [ ! -f /root/go/bin/kubecolor ]; then
go get github.com/dty1er/kubecolor/cmd/kubecolor
echo "alias kubectl=kubecolor" >> /etc/profile
alias kubectl=kubecolor
#apt -y autoremove golang-go
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

# Install Skaffold
ARCH=amd64
if [ ! -f /usr/local/bin/skaffold ]; then
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-${ARCH} && \
install skaffold /usr/local/bin/
rm skaffold
skaffold completion bash >/etc/bash_completion.d/skaffold
source /etc/bash_completion.d/skaffold
fi

# Misc
apt -y install postgresql-client mysql-client jq lynx

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Kubernetes tools was installed in Ubuntu"
echo "please re-login again"
