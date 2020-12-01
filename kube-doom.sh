#!/usr/bin/env bash

if [ ${EUID:-${UID}} != 0 ]; then
    echo "This script must be run as root"
    exit 1
else
    echo "I am root user."
fi

git clone https://github.com/storax/kubedoom --depth 1
cd kubedoom
kubectl apply -f manifest/
namespace/kubedoom created
deployment.apps/kubedoom created
serviceaccount/kubedoom created
clusterrolebinding.rbac.authorization.k8s.io/kubedoom created
cd ..
rm -rf kubedoom
echo ""
echo "*************************************************************************************"
echo "Next Step"
echo "kubectl -n kubedoom port-forward --address 0.0.0.0 deployment/kubedoom 5900:5900"
echo "connect hostIP:5900 with vncviewer"
echo "Password is idbehold"
