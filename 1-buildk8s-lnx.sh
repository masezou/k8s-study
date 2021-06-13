#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

# Install Kind
uname -r | grep Microsoft
KENELRTVL=$?
if [ ${KENELRTVL} != 0 ]; then
    KINDVER=0.11.1
    KINDARCH=amd64
	if [ ! -f /usr/local/bin/kind ]; then
	apt -y install docker.io
	curl -s -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v${KINDVER}/kind-linux-${KINDARCH}
	chmod +x ./kind
	mv ./kind /usr/local/bin/kind
	kind completion bash > /etc/bash_completion.d/kind
	source /etc/bash_completion.d/kind
	fi
fi

# Bulding Kind Cluster
if [  -f /usr/local/bin/kind ]; then
LOCALIPADDR=`ip -f inet -o addr show ens160 |cut -d\  -f 7 | cut -d/ -f 1`
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
fi

echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "Kubernetes was build with kind"
