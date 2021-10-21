#!/usr/bin/env bash

#########################################################
### UID Check ###
if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

### Distribution Check ###
lsb_release -d | grep Ubuntu | grep 20.04
DISTVER=$?
if [ ${DISTVER} = 1 ]; then
    echo "only supports Ubuntu 20.04 server"
    exit 1
else
    echo "Ubuntu 20.04=OK"
fi

### ARCH Check ###
PARCH=`arch`
if [ ${PARCH} = aarch64 ]; then
  ARCH=arm64
  echo ${ARCH}
elif [ ${PARCH} = arm64 ]; then
  ARCH=arm64
  echo ${ARCH}
elif [ ${PARCH} = x86_64 ]; then
  ARCH=amd64
  echo ${ARCH}
else
  echo "${ARCH} platform is not supported"
  exit 1
fi

#########################################################

BASEPWD=`pwd`

# Install kubecolor
if [ ! -f /usr/bin/go ]; then
apt -y install golang-go
export GOPATH=$HOME/go
echo 'export GOPATH=$HOME/go' >>/etc/profile
echo 'export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin' >>/etc/profile
export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin
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
if [ ! -f /usr/local/bin/skaffold ]; then
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-${ARCH} && \
install skaffold /usr/local/bin/
rm skaffold
skaffold completion bash >/etc/bash_completion.d/skaffold
source /etc/bash_completion.d/skaffold
fi

# Install Minio client
if [ ! -f /usr/local/bin/mc ]; then
curl -OL https://dl.min.io/client/mc/release/linux-${ARCH}/mc
mv mc /usr/local/bin/
chmod +x /usr/local/bin/mc
echo "complete -C /usr/local/bin/mc mc" > /etc/bash_completion.d/mc.sh
/usr/local/bin/mc >/dev/null
fi

# Install kubectx and kubens
KUBECTX=0.9.4
if [ ! -f /usr/local/bin/kubectx ]; then
if [ ${ARCH} = amd64 ]; then
	ARCH=x86_64
fi
curl -OL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX}/kubectx_v${KUBECTX}_linux_${ARCH}.tar.gz
tar xfz kubectx_v${KUBECTX}_linux_${ARCH}.tar.gz
mv kubectx /usr/local/bin/
chmod +x /usr/local/bin/kubectx
rm -rf LICENSE kubectx_v${KUBECTX}_linux_${ARCH}.tar.gz
curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash
mv kubectx.bash /etc/bash_completion.d/
source /etc/bash_completion.d/kubectx.bash
curl -OL https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX}/kubens_v${KUBECTX}_linux_${ARCH}.tar.gz
tar xfz kubens_v${KUBECTX}_linux_${ARCH}.tar.gz
mv kubens /usr/local/bin/
chmod +x /usr/local/bin/kubens
curl -OL https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash
mv kubens.bash /etc/bash_completion.d/
source /etc/bash_completion.d/kubens.bash
rm -rf LICENSE kubens_v${KUBECTX}_linux_${ARCH}.tar.gz
apt -y install fzf
fi

# Install octant
if [ ! -f /usr/local/bin/octant ]; then
   OCTANT=0.24.0
   if [ ${ARCH} = amd64 ]; then
      curl -OL https://github.com/vmware-tanzu/octant/releases/download/v${OCTANT}/octant_${OCTANT}_Linux-64bit.deb
      dpkg -i octant_${OCTANT}_Linux-64bit.deb
     rm dpkg -i octant_${OCTANT}_Linux-64bit.deb
   fi

   if [ ${ARCH} = armd64 ]; then
      curl -OL https://github.com/vmware-tanzu/octant/releases/download/v${OCTANT}/octant_${OCTANT}_Linux-ARM.deb
      dpkg -i octant_${OCTANT}_Linux-ARM.deb
      rm octant_${OCTANT}_Linux-ARM.deb
   fi
   mkdir -p $HOME/.config/octant/plugins/
git clone --depth 1 git@github.com:ashish-amarnath/octant-velero-plugin.git
cd octant-velero-plugin/
make install
cd ..

  mkdir -p $HOME/.config/octant/plugins/ && \
  curl -L https://github.com/bloodorangeio/octant-helm/releases/download/v0.2.0/octant-helm_0.2.0_linux_amd64.tar.gz | \
  tar xz -C ~/.config/octant/plugins/ octant-helm

  mkdir -p $HOME/.config/octant/plugins/ 
  git clone --depth 1 git@github.com:vmware-tanzu/octant-plugin-for-kind.git
  cd octant-plugin-for-kind
  make
  cp bin/octant-plugin-for-kind $HOME/.config/octant/plugins/

fi

echo "export OCTANT_LISTENER_ADDR=0.0.0.0:8090" >> /etc/profile

# Misc
apt -y install postgresql-contrib postgresql-client mysql-client jq lynx
systemctl stop postgresql
systemctl disable postgresql

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Kubernetes tools was installed in Ubuntu"
echo "please re-login again"

cd ${BASEPWD}
chmod -x ./2-tool.sh
