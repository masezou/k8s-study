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

### CPU Core count Check ###
CPUCORECOUNT=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`
echo "CPU is ${CPUCORECOUNT}"
if [ ${CPUCORECOUNT} -ge 4 ]; then
 echo "CPU core count is OK"
else
 echo "Too small CPU core count, please add cpu core at  least 4vCPU"
 exit 1
fi  

PHYSICALMEM=`free | grep Mem | awk '{ print $2*100 }'`
echo ${PHYSICALMEM}
  if [ ${PHYSICALMEM} -lt 1600000000 ]; then
  echo "At least need to have 16GB Memory..."
  echo "please shudown now and add memory, then try again!"
  exit 255
fi

#### LOCALIP #########
ip address show ens160 >/dev/null
retval=$?
if [ ${retval} -eq 0 ]; then
        LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
else
  ip address show ens192 >/dev/null
  retval2=$?
  if [ ${retval2} -eq 0 ]; then
        LOCALIPADDR=`ip -f inet -o addr show ens192 |cut -d\  -f 7 | cut -d/ -f 1`
  else
        LOCALIPADDR=`ip -f inet -o addr show eth0 |cut -d\  -f 7 | cut -d/ -f 1`
  fi
fi
echo ${LOCALIPADDR}

#########################################################

apt update
apt -y upgrade

# Install Docker and Kind
uname -r | grep Microsoft
KENELRTVL=$?
if [ ${KENELRTVL} != 0 ]; then
	if [ ! -f /usr/bin/docker ]; then
    DOCKERVER="5:20.10.10~3-0~ubuntu-focal"
    apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common nfs-kernel-server smbclient cifs-utils
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    apt-key fingerprint 0EBFCD88
     if [ ${ARCH} = amd64 ]; then
        add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
     elif [ ${ARCH} = arm64 ]; then
        add-apt-repository  "deb [arch=arm64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
     else
        echo "${ARCH} platform is not supported"
        exit 1
     fi
    apt -y purge docker.io
    apt update
    apt -y install docker-ce-cli=${DOCKERVER} docker-ce=${DOCKERVER} docker-ce-rootless-extras=${DOCKERVER}
    apt-mark hold docker-ce-cli docker-ce docker-ce-rootless-extras
    groupadd docker

    for DOCKERUSER in `ls -1 /home | grep -v linuxbrew`; do
      echo ${DOCKERUSER}
      gpasswd -a ${DOCKERUSER} docker
    done
    systemctl enable docker
    systemctl daemon-reload
    systemctl restart docker
    fi
    KINDVER=0.11.1
	if [ ! -f /usr/local/bin/kind ]; then
	curl -s -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v${KINDVER}/kind-linux-${ARCH}
	chmod +x ./kind
	mv ./kind /usr/local/bin/kind
	kind completion bash > /etc/bash_completion.d/kind
	source /etc/bash_completion.d/kind
	fi
fi

# Install kubectl
if [ ! -f /usr/bin/kubectl ]; then
apt update
apt -y install apt-transport-https gnupg2 curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
apt update
KUBECTLVER=1.21.1-00
apt -y install -qy kubectl=${KUBECTLVER}
apt-mark hold kubectl
kubectl completion bash >/etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
echo 'export KUBE_EDITOR=vi' >>~/.bashrc
fi



#### Local Registry Contaner
# create registry container unless it already exists
mkdir -p /disk/registry
reg_name='kind-registry'
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -v /disk/registry:/var/lib/registry -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# Bulding Kind Cluster
if [  -f /usr/local/bin/kind ]; then
#Kind 0.7.0
#kind create cluster --name k10-demo --image kindest/node:v1.11.10 --wait 600s
#Kind 0.8.0
#kind create cluster --name k10-demo --image kindest/node:v1.12.10 --wait 600s
#Kind 0.9.0
#kind create cluster --name k10-demo --image kindest/node:v1.13.12 --wait 600s
#Kind 0.11.1
#kind create cluster --name k10-demo --image kindest/node:v1.14.10 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.15.12 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.17.17 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.18.19 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.19.11 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.20.7 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.21.1 --wait 600s
#kind create cluster --name k10-demo --image kindest/node:v1.22.0 --wait 600s

K8SVER=v1.21.1
CLUSTERNAME=k10-demo
cat <<EOF | kind create cluster --name ${CLUSTERNAME} --image kindest/node:${K8SVER} --wait 600s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
#featureGates:
  # any feature gate can be enabled here with "Name": true
  # or disabled here with "Name": false
  # not all feature gates are tested, however
  #"CSIMigration": true
  #"CSIMigrationvSphere": true
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:5000"]
networking:
  # WARNING: It is _strongly_ recommended that you keep this the default
  # (127.0.0.1) for security reasons. However it is possible to change this.
  apiServerAddress: "${LOCALIPADDR}"
  # By default the API server listens on a random open port.
  # You may choose a specific port but probably don't need to in most cases.
  # Using a random port makes it easier to spin up multiple clusters.
#  apiServerPort: 6443
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
- role: worker
- role: worker
- role: worker
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
kubectl label node ${CLUSTERNAME}-worker node-role.kubernetes.io/worker=worker
kubectl label node ${CLUSTERNAME}-worker2 node-role.kubernetes.io/worker=worker
kubectl label node ${CLUSTERNAME}-worker3 node-role.kubernetes.io/worker=worker

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

sleep 10
# connect the registry to the cluster network
# (the network may already be connected)
docker network connect "kind" "${reg_name}" || true
fi


# Private Registry Front End
#docker run -d --name repositoryfe -e ENV_DOCKER_REGISTRY_HOST=${LOCALIPADDR} -e ENV_DOCKER_REGISTRY_PORT=5000 -p 18082:80  ekazakov/docker-registry-frontend

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Private registory fe"
echo "http://${LOCALIPADDR}:18082"

echo "Kubernetes was build with kind"

chmod -x ./1-buildk8s-lnx.sh
